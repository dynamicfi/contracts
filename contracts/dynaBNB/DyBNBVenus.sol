// contracts/venus/DyBNBVenus.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../DyETH.sol";
import "./interfaces/IVenusBNBDelegator.sol";
import "./interfaces/IVenusBEP20Delegator.sol";
import "./interfaces/IVenusUnitroller.sol";
import "./interfaces/IPancakeRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/VenusLibrary.sol";

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

contract DyBNBVenus is Ownable, DyETH {
    using SafeMath for uint256;

    struct LeverageSettings {
        uint256 leverageLevel;
        uint256 leverageBips;
        uint256 minMinting;
    }

    struct BorrowBalance {
        uint256 supply;
        uint256 loan;
    }

    mapping(address => BorrowBalance) public userBorrow;

    event TrackingDeposit(uint256 amount, uint256 usdt);
    event TrackingUserDeposit(address user, uint256 amount);
    event TrackingWithdraw(uint256 amount, uint256 usdt);
    event TrackingUserWithdraw(address user, uint256 amount);
    event TrackingInterest(uint256 moment, uint256 amount);
    event TrackingUserInterest(address user, uint256 amount);

    IVenusBNBDelegator public tokenDelegator;
    IVenusUnitroller public rewardController;
    IERC20 public xvsToken;
    IERC20 public WBNB;
    IPancakeRouter public pancakeRouter;
    uint256 public leverageLevel;
    uint256 public leverageBips;
    uint256 public minMinting;
    uint256 public redeemLimitSafetyMargin;
    uint256 public totalInterest;

    constructor(
        string memory name_,
        string memory symbol_,
        address tokenDelegator_,
        address rewardController_,
        address xvsAddress_,
        address WBNB_,
        address USD_,
        address pancakeRouter_,
        LeverageSettings memory leverageSettings_
    ) DyETH(name_, symbol_) {
        tokenDelegator = IVenusBNBDelegator(tokenDelegator_);
        rewardController = IVenusUnitroller(rewardController_);
        minMinting = leverageSettings_.minMinting;
        _updateLeverage(
            leverageSettings_.leverageLevel,
            leverageSettings_.leverageBips,
            leverageSettings_.leverageBips.mul(990).div(1000) //works as long as leverageBips > 1000
        );
        xvsToken = IERC20(xvsAddress_);
        WBNB = IERC20(WBNB_);
        USD = USD_;
        pancakeRouter = IPancakeRouter(pancakeRouter_);
        _enterMarket();
        updateDepositsEnabled(true);
    }

    function deposit(uint256 amountUnderlying_) public payable override(DyETH) {
        super.deposit(amountUnderlying_);
        emit TrackingDeposit(amountUnderlying_, _getVaultValueInDollar());
        emit TrackingUserDeposit(_msgSender(), amountUnderlying_);
    }

    function withdraw(uint256 amount_) public override(DyETH) {
        super.withdraw(amount_);
        DepositStruct storage user = userInfo[_msgSender()];
        uint256 reward = user.rewardBalance;
        user.rewardBalance = 0;
        (bool success, ) = _msgSender().call{value: reward}("");
        require(success, "Transfer ETH failed");
        emit TrackingWithdraw(amount_, _getVaultValueInDollar());
        emit TrackingUserWithdraw(_msgSender(), amount_);
    }

    function totalDeposits() public view virtual override returns (uint256) {
        (
            ,
            uint256 internalBalance,
            uint256 borrowAmount,
            uint256 exchangeRate
        ) = tokenDelegator.getAccountSnapshot(address(this));
        return internalBalance.mul(exchangeRate).div(1e18).sub(borrowAmount);
    }

    function _totalDepositsFresh() internal override returns (uint256) {
        uint256 borrowAmount = tokenDelegator.borrowBalanceCurrent(
            address(this)
        );
        uint256 balance = tokenDelegator.balanceOfUnderlying(address(this));
        return balance.sub(borrowAmount);
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

    function updateMinimumBoundaries(
        uint256 redeemLimitSafetyMargin_,
        uint256 minMinting_
    ) public onlyOwner {
        minMinting = minMinting_;
        redeemLimitSafetyMargin = redeemLimitSafetyMargin_;
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
        require(amountUnderlying_ > 0, "DyBNBVenus::stakeDepositTokens");
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
                "DyBNBVenus::borrowing failed"
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
            "DyBNBVenus::below minimum withdraw"
        );
        _unrollDebt(amountUnderlying_);
        uint256 success = tokenDelegator.redeemUnderlying(amountUnderlying_);
        require(success == 0, "DyBNBVenus::failed to redeem");
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
                "DyBNBVenus::failed to redeem"
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
            uint256 borrowAmount,
            uint256 exchangeRate
        ) = tokenDelegator.getAccountSnapshot(address(this));
        uint256 balance = internalBalance.mul(exchangeRate).div(1e18);
        return balance.mul(1e18).div(balance.sub(borrowAmount));
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
        uint256 reward = distributeReward();
        totalInterest += reward;
        rewardController.claimVenus(address(this), markets);

        uint256 xvsBalance = xvsToken.balanceOf(address(this));
        if (xvsBalance > 0) {
            xvsToken.approve(address(pancakeRouter), xvsBalance);
            address[] memory path = new address[](2);
            path[0] = address(xvsToken);
            path[1] = address(WBNB);
            uint256 _deadline = block.timestamp + 3000;
            pancakeRouter.swapExactTokensForETH(
                xvsBalance,
                0,
                path,
                address(this),
                _deadline
            );
        }

        _distributeRewardByAmount(reward);

        uint256 amount = address(this).balance;
        if (userDeposit == 0) {
            require(amount >= minTokensToReinvest, "DyBNBVenus::reinvest");
        }

        if (amount > 0) {
            _stakeDepositTokens(amount);
        }

        emit Reinvest(totalDeposits(), totalSupply());
        emit TrackingInterest(block.timestamp, reward);
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
            "DyBNBVenus::rescueDeployedFunds"
        );
        if (depositEnable == true) {
            updateDepositsEnabled(false);
        }
    }

    function distributeReward() public view returns (uint256) {
        uint256 xvsRewards = VenusLibrary.calculateReward(
            rewardController,
            IVenusBEP20Delegator(address(tokenDelegator)),
            address(this)
        );
        if (xvsRewards == 0) {
            return 0;
        }
        address[] memory path = new address[](3);
        path[0] = address(xvsToken);
        path[1] = address(WBNB);
        uint256[] memory amounts = pancakeRouter.getAmountsOut(
            xvsRewards,
            path
        );
        return amounts[2];
    }

    function _distributeRewardByAmount(uint256 _rewardAmount) internal {
        uint256 totalProduct = _calculateTotalProduct();
        for (uint256 i = 0; i < depositors.length; i++) {
            DepositStruct storage user = userInfo[depositors[i]];
            uint256 stackingPeriod = block.timestamp - user.lastDepositTime;
            uint256 APY = _getAPYValue();
            uint256 interest = (_rewardAmount * user.amount * stackingPeriod) /
                totalProduct +
                (user.amount * stackingPeriod * APY) /
                (ONE_MONTH_IN_SECONDS * 1000);
            user.rewardBalance += (interest * 90) / 100; // 10 % performance fee
            user.lastDepositTime = block.timestamp;
            emit TrackingUserInterest(depositors[i], interest);
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

    function _getAPYValue() public view returns (uint256) {
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
        if (totalTokenStack == 0) {
            return 0;
        }
        address[] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(USD);
        uint256[] memory amounts = pancakeRouter.getAmountsOut(
            totalTokenStack,
            path
        );
        return amounts[1];
    }

    function supplyCollateral(uint256 _amount) public payable {
        tokenDelegator.mint{value: _amount}();

        BorrowBalance storage userBorrowBalance = userBorrow[msg.sender];
        userBorrowBalance.supply += _amount;
    }

    function borrow(uint256 _amount) public {
        BorrowBalance storage userBorrowBalance = userBorrow[msg.sender];
        require(
            tokenDelegator.borrow(_amount) == 0,
            "DyBEP20Venus::Borrowing failed"
        );

        userBorrowBalance.loan += _amount;
    }

    function repay(uint256 _amount) public payable {
        BorrowBalance storage userBorrowBalance = userBorrow[msg.sender];
        tokenDelegator.repayBorrow{value: _amount}();

        userBorrowBalance.loan -= _amount;
    }

    // function _getDynaPriceInDollar(uint256 _dynaAmount)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     if (_dynaAmount == 0) {
    //         return 0;
    //     }
    //     address[] memory path = new address[](3);
    //     path[0] = address(DYNA);
    //     path[1] = address(WBNB);
    //     path[2] = address(USD);
    //     uint256[] memory amounts = pancakeRouter.getAmountsOut(
    //         _dynaAmount,
    //         path
    //     );
    //     return amounts[2];
    // }

    // function _cashOutDyna(
    //     address _receiver,
    //     uint256 _amount,
    //     address _tokenOut
    // ) internal override {
    //     IERC20 dyna = IERC20(DYNA);
    //     if (_tokenOut == DYNA) {
    //         dyna.transferFrom(owner(), address(this), _amount);
    //         dyna.transfer(_receiver, _amount);
    //         return;
    //     }
    //     dyna.transferFrom(owner(), address(this), _amount);
    //     dyna.approve(address(pancakeRouter), _amount);
    //     uint256 _deadline = block.timestamp + 3000;

    //     if (_tokenOut == address(WBNB)) {
    //         address[] memory path = new address[](2);
    //         path[0] = address(DYNA);
    //         path[1] = address(WBNB);

    //         pancakeRouter.swapExactTokensForTokens(
    //             _amount,
    //             0,
    //             path,
    //             _receiver,
    //             _deadline
    //         );
    //     } else {
    //         address[] memory path = new address[](3);
    //         path[0] = address(DYNA);
    //         path[1] = address(WBNB);
    //         path[2] = _tokenOut;

    //         pancakeRouter.swapExactTokensForTokens(
    //             _amount,
    //             0,
    //             path,
    //             _receiver,
    //             _deadline
    //         );
    //     }
    // }
}
