// contracts/compound/DyETHCompound.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../DyETH.sol";
import "./interfaces/ICompoundETHDelegator.sol";
import "./interfaces/ICompoundERC20Delegator.sol";
import "./interfaces/ICompoundUnitroller.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH9.sol";

import "./lib/CompoundLibrary.sol";

/**
 ________      ___    ___ ________   ________  _____ ______   ___  ________     
|\   ___ \    |\  \  /  /|\   ___  \|\   __  \|\   _ \  _   \|\  \|\   ____\    
\ \  \_|\ \   \ \  \/  / | \  \\ \  \ \  \|\  \ \  \\\__\ \  \ \  \ \  \___|    
 \ \  \ \\ \   \ \    / / \ \  \\ \  \ \   __  \ \  \\|__| \  \ \  \ \  \       
  \ \  \_\\ \   \/  /  /   \ \  \\ \  \ \  \ \  \ \  \    \ \  \ \  \ \  \____  
   \ \_______\__/  / /      \ \__\\ \__\ \__\ \__\ \__\    \ \__\ \__\ \_______\
    \|_______|\___/ /        \|__| \|__|\|__|\|__|\|__|     \|__|\|__|\|_______|
             \|___|/                                                            
 */

contract DyETHCompound is DyETH {
    using SafeMath for uint256;

    struct LeverageSettings {
        uint256 leverageLevel;
        uint256 leverageBips;
        uint256 minMinting;
    }

    ICompoundETHDelegator public tokenDelegator;
    ICompoundUnitroller public rewardController;
    IERC20 public compToken;
    IWETH9 public WETH;
    ISwapRouter public swapRouter;
    uint256 public leverageLevel;
    uint256 public leverageBips;
    uint256 public minMinting;
    uint256 public redeemLimitSafetyMargin;

    constructor(
        string memory name_,
        string memory symbol_,
        address tokenDelegator_,
        address rewardController_,
        address compAddress_,
        address WETH_,
        address DYNA_,
        address USD_,
        address swapRouter_,
        LeverageSettings memory leverageSettings_
    ) DyETH(name_, symbol_) {
        tokenDelegator = ICompoundETHDelegator(tokenDelegator_);
        rewardController = ICompoundUnitroller(rewardController_);
        minMinting = leverageSettings_.minMinting;
        _updateLeverage(
            leverageSettings_.leverageLevel,
            leverageSettings_.leverageBips,
            leverageSettings_.leverageBips.mul(990).div(1000) //works as long as leverageBips > 1000
        );
        compToken = IERC20(compAddress_);
        WETH = IWETH9(WETH_);
        DYNA = DYNA_;
        USD = USD_;
        swapRouter = ISwapRouter(swapRouter_);
        _enterMarket();
        updateDepositsEnabled(true);
    }

    function totalDeposits() public view virtual override returns (uint256) {
        (
            ,
            uint256 internalBalance,
            uint256 borrow,
            uint256 exchangeRate
        ) = tokenDelegator.getAccountSnapshot(address(this));
        return internalBalance.mul(exchangeRate).div(1e18).sub(borrow);
    }

    function _totalDepositsFresh() internal override returns (uint256) {
        uint256 borrow = tokenDelegator.borrowBalanceCurrent(address(this));
        uint256 balance = tokenDelegator.balanceOfUnderlying(address(this));
        return balance.sub(borrow);
    }

    function updateLeverage(
        uint256 _leverageLevel,
        uint256 _leverageBips,
        uint256 _redeemLimitSafetyMargin
    ) external onlyOwner {
        _updateLeverage(
            _leverageLevel,
            _leverageBips,
            _redeemLimitSafetyMargin
        );

        (uint256 balance, uint256 borrowed) = _getAccountData();
        _unrollDebt(balance.sub(borrowed));
        _rollupDebt();
    }

    function _updateLeverage(
        uint256 leverageLevel_,
        uint256 leverageBips_,
        uint256 redeemLimitSafetyMargin_
    ) internal {
        leverageLevel = leverageLevel_;
        leverageBips = leverageBips_;
        redeemLimitSafetyMargin = redeemLimitSafetyMargin_;
    }

    function _enterMarket() internal {
        address[] memory tokens = new address[](1);
        tokens[0] = address(tokenDelegator);
        rewardController.enterMarkets(tokens);
    }

    function _stakeDepositTokens(uint256 amountUnderlying_)
        internal
        virtual
        override
    {
        require(amountUnderlying_ > 0, "DyETHCompound::stakeDepositTokens");
        tokenDelegator.mint{value: amountUnderlying_}();
        _rollupDebt();
    }

    function _rollupDebt() internal {
        (uint256 balance, uint256 borrowed) = _getAccountData();
        (uint256 borrowLimit, uint256 borrowBips) = _getBorrowLimit();
        uint256 lendTarget = balance.sub(borrowed).mul(leverageLevel).div(
            leverageBips
        );
        while (balance < lendTarget) {
            uint256 toBorrowAmount = _getBorrowable(
                balance,
                borrowed,
                borrowLimit,
                borrowBips
            );
            if (balance.add(toBorrowAmount) > lendTarget) {
                toBorrowAmount = lendTarget.sub(balance);
            }

            // safeguard needed because we can't mint below a certain threshold
            if (toBorrowAmount < minMinting) {
                break;
            }
            require(
                tokenDelegator.borrow(toBorrowAmount) == 0,
                "DyETHCompound::borrowing failed"
            );
            tokenDelegator.mint{value: toBorrowAmount}();
            (balance, borrowed) = _getAccountData();
        }
    }

    function _getAccountData() internal returns (uint256, uint256) {
        uint256 balance = tokenDelegator.balanceOfUnderlying(address(this));
        uint256 borrowed = tokenDelegator.borrowBalanceCurrent(address(this));
        return (balance, borrowed);
    }

    function _getBorrowable(
        uint256 balance_,
        uint256 borrowed_,
        uint256 borrowLimit_,
        uint256 bips_
    ) internal pure returns (uint256) {
        return balance_.mul(borrowLimit_).div(bips_).sub(borrowed_);
    }

    function _getBorrowLimit() internal view returns (uint256, uint256) {
        (, uint256 borrowLimit) = rewardController.markets(
            address(tokenDelegator)
        );
        return (borrowLimit, 1e18);
    }

    function _withdrawDepositTokens(uint256 amountUnderlying_)
        internal
        virtual
        override
    {
        require(
            amountUnderlying_ >= minMinting,
            "DyETHCompound::below minimum withdraw"
        );
        _unrollDebt(amountUnderlying_);
        uint256 success = tokenDelegator.redeemUnderlying(amountUnderlying_);
        require(success == 0, "DyETHCompound::failed to redeem");
    }

    receive() external payable {}

    function _getRedeemable(
        uint256 balance,
        uint256 borrowed,
        uint256 borrowLimit,
        uint256 bips
    ) internal view returns (uint256) {
        return
            balance
                .sub(borrowed.mul(bips).div(borrowLimit))
                .mul(redeemLimitSafetyMargin)
                .div(leverageBips);
    }

    function _unrollDebt(uint256 amountToBeFreed_) internal {
        (uint256 balance, uint256 borrowed) = _getAccountData();
        if (borrowed == 0) return;
        (uint256 borrowLimit, uint256 borrowBips) = _getBorrowLimit();
        uint256 targetBorrow = balance
            .sub(borrowed)
            .sub(amountToBeFreed_)
            .mul(leverageLevel)
            .div(leverageBips)
            .sub(balance.sub(borrowed).sub(amountToBeFreed_));
        uint256 toRepay = borrowed.sub(targetBorrow);
        while (toRepay > 0) {
            uint256 unrollAmount = _getRedeemable(
                balance,
                borrowed,
                borrowLimit,
                borrowBips
            );
            if (unrollAmount > toRepay) {
                unrollAmount = toRepay;
            }
            require(
                tokenDelegator.redeemUnderlying(unrollAmount) == 0,
                "DyETHCompound::failed to redeem"
            );
            tokenDelegator.repayBorrow{value: unrollAmount}();
            (balance, borrowed) = _getAccountData();
            if (targetBorrow >= borrowed) {
                break;
            }
            toRepay = borrowed.sub(targetBorrow);
        }
    }

    function getActualLeverage() public view returns (uint256) {
        (
            ,
            uint256 internalBalance,
            uint256 borrow,
            uint256 exchangeRate
        ) = tokenDelegator.getAccountSnapshot(address(this));
        uint256 balance = internalBalance.mul(exchangeRate).div(1e18);
        return balance.mul(1e18).div(balance.sub(borrow));
    }

    function reinvest() external nonReentrant {
        _reinvest(0);
    }

    /**
     * @notice Reinvest rewards from staking contract to deposit tokens
     */
    function _reinvest(uint256 userDeposit) private {
        address[] memory markets = new address[](1);
        markets[0] = address(tokenDelegator);
        uint256 dynaReward = distributeReward();
        rewardController.claimComp(address(this), markets);

        uint256 compBalance = compToken.balanceOf(address(this));
        if (compBalance > 0) {
            compToken.approve(address(swapRouter), compBalance);
            address[] memory path = new address[](3);
            path[0] = address(compToken);
            path[1] = address(WETH);
            path[2] = address(DYNA);
            uint256 _deadline = block.timestamp + 3000;
            swapRouter.swapExactTokensForTokens(
                compBalance,
                0,
                path,
                address(this),
                _deadline
            );
        }

        _distributeDynaByAmount(dynaReward);

        uint256 amount = address(this).balance;
        if (userDeposit == 0) {
            require(amount >= minTokensToReinvest, "DyETHCompound::reinvest");
        }

        if (amount > 0) {
            _stakeDepositTokens(amount);
        }

        emit Reinvest(totalDeposits(), totalSupply());
    }

    function rescueDeployedFunds(uint256 minReturnAmountAccepted)
        external
        onlyOwner
    {
        uint256 balanceBefore = address(this).balance;
        (uint256 balance, uint256 borrowed) = _getAccountData();
        _unrollDebt(balance.sub(borrowed));
        tokenDelegator.redeemUnderlying(
            tokenDelegator.balanceOfUnderlying(address(this))
        );
        uint256 balanceAfter = address(this).balance;
        require(
            balanceAfter.sub(balanceBefore) >= minReturnAmountAccepted,
            "DyETHCompound::rescueDeployedFunds"
        );
        if (depositEnable == true) {
            updateDepositsEnabled(false);
        }
    }

    function distributeReward() public view returns (uint256) {
        uint256 compRewards = CompoundLibrary.calculateReward(
            rewardController,
            ICompoundERC20Delegator(address(tokenDelegator)),
            address(this)
        );
        if (compRewards == 0) {
            return 0;
        }
        address[] memory path = new address[](3);
        path[0] = address(compToken);
        path[1] = address(WETH);
        path[2] = address(DYNA);
        uint256[] memory amounts = swapRouter.getAmountsOut(compRewards, path);
        return amounts[2];
    }

    function _distributeDynaByAmount(uint256 _dynaAmount) internal {
        uint256 totalProduct = _calculateTotalProduct();
        for (uint256 i = 0; i < depositors.length; i++) {
            DepositStruct storage user = userInfo[depositors[i]];
            uint256 stackingPeriod = block.timestamp - user.lastDepositTime;
            uint256 APY = _getAPYValue();
            user.dynaBalance +=
                (_dynaAmount * user.amount * stackingPeriod) /
                totalProduct +
                (user.amount * stackingPeriod * APY) /
                (ONE_MONTH_IN_SECONDS * 1000);
            user.lastDepositTime = block.timestamp;
        }
    }

    function _calculateTotalProduct() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < depositors.length; i++) {
            DepositStruct memory user = userInfo[depositors[i]];
            total += user.amount * (block.timestamp - user.lastDepositTime);
        }
        return total;
    }

    function _getAPYValue() internal view returns (uint256) {
        uint256 totalValue = _getVaultValueInDollar();
        uint256 percent = 0;

        for (uint256 i = 0; i < totalValues.length; i++) {
            if (totalValue >= totalValues[i]) {
                percent = percentByValues[i];
                break;
            }
        }

        return percent;
    }

    function _getVaultValueInDollar() internal view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(compToken);
        path[1] = address(WETH);
        path[2] = address(DYNA);
        uint256[] memory amounts = swapRouter.getAmountsOut(
            totalTokenStack,
            path
        );
        return amounts[2];
    }
}
