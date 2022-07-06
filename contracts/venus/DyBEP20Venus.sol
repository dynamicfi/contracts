// contracts/DyERC20.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../DyERC20.sol";
import "./interfaces/IVenusBEP20Delegator.sol";
import "./interfaces/IVenusUnitroller.sol";

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

contract DyBEP20Venus is DyERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct LeverageSettings {
        uint256 leverageLevel;
        uint256 leverageBips;
        uint256 minMinting;
    }

    IVenusBEP20Delegator public tokenDelegator;
    IVenusUnitroller public rewardController;
    uint256 private leverageLevel;
    uint256 private leverageBips;
    uint256 private minMinting;
    uint256 private redeemLimitSafetyMargin;

    event Failure(uint256 code, string info);

    constructor(
        address underlying_,
        string memory name_,
        string memory symbol_,
        address tokenDelegator_,
        address rewardController_,
        LeverageSettings memory leverageSettings_
    ) DyERC20(underlying_, name_, symbol_) {
        tokenDelegator = IVenusBEP20Delegator(tokenDelegator_);
        rewardController = IVenusUnitroller(rewardController_);
        minMinting = leverageSettings_.minMinting;
        _updateLeverage(
            leverageSettings_.leverageLevel,
            leverageSettings_.leverageBips,
            leverageSettings_.leverageBips.mul(990).div(1000) //works as long as leverageBips > 1000
        );
        _enterMarket();
        updateDepositsEnabled(true);
    }

    function totalDeposits() public view virtual override returns (uint256) {
        (uint256 balance, uint256 borrowed) = _getAccountData();
        return balance.sub(borrowed);
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
        require(amountUnderlying_ > 0, "DyBEP20Venus::stakeDepositTokens");
        underlying.approve(address(tokenDelegator), amountUnderlying_);
        uint256 success = tokenDelegator.mint(amountUnderlying_);
        require(success == 0, "DyBEP20Venus::Deposit failed");
        _rollupDebt();
    }

    function _rollupDebt() internal {
        (uint256 balance, uint256 borrowed) = _getAccountData();
        (uint256 borrowLimit, uint256 borrowBips) = _getBorrowLimit();
        uint256 lendTarget = balance.sub(borrowed).mul(leverageLevel).div(
            leverageBips
        );
        IERC20(underlying).approve(address(tokenDelegator), lendTarget);
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
                "DyBEP20Venus::borrowing failed"
            );
            require(
                tokenDelegator.mint(toBorrowAmount) == 0,
                "DyBEP20Venus::lending failed"
            );
            (balance, borrowed) = _getAccountData();
        }
        underlying.approve(address(tokenDelegator), 0);
    }

    function _getAccountData()
        internal
        view
        returns (uint256 balance, uint256 borrowed)
    {
        balance = tokenDelegator.balanceOfUnderlying(address(this));
        borrowed = tokenDelegator.borrowBalanceCurrent(address(this));
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
            amountUnderlying_ > minMinting,
            "DyBEP20Venus::below minimum withdraw"
        );
        _unrollDebt(amountUnderlying_);
        uint256 success = tokenDelegator.redeemUnderlying(amountUnderlying_);
        require(success == 0, "DyBEP20Venus::failed to redeem");
    }

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
        (uint256 borrowLimit, uint256 borrowBips) = _getBorrowLimit();
        uint256 targetBorrow = balance
            .sub(borrowed)
            .sub(amountToBeFreed_)
            .mul(leverageLevel)
            .div(leverageBips)
            .sub(balance.sub(borrowed).sub(amountToBeFreed_));
        uint256 toRepay = borrowed.sub(targetBorrow);
        underlying.approve(address(tokenDelegator), borrowed);
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
                "DyBEP20Venus::failed to redeem"
            );
            require(
                tokenDelegator.repayBorrow(unrollAmount) == 0,
                "DyBEP20Venus::failed to repay borrow"
            );
            (balance, borrowed) = _getAccountData();
            if (targetBorrow >= borrowed) {
                break;
            }
            toRepay = borrowed.sub(targetBorrow);
        }
        underlying.approve(address(tokenDelegator), 0);
    }

    function getActualLeverage() public view returns (uint256) {
        (uint256 balance, uint256 borrowed) = _getAccountData();
        return balance.mul(1e18).div(balance.sub(borrowed));
    }

    function rescueDeployedFunds(
        uint256 minReturnAmountAccepted
    ) external onlyOwner {
        uint256 balanceBefore = underlying.balanceOf(address(this));
        (uint256 balance, uint256 borrowed) = _getAccountData();
        _unrollDebt(balance.sub(borrowed));
        tokenDelegator.redeemUnderlying(tokenDelegator.balanceOfUnderlying(address(this)));
        uint256 balanceAfter = underlying.balanceOf(address(this));
        require(balanceAfter.sub(balanceBefore) >= minReturnAmountAccepted, "DyBEP20Venus::rescueDeployedFunds");
        if (depositEnable == true) {
            updateDepositsEnabled(false);
        }
    }
}
