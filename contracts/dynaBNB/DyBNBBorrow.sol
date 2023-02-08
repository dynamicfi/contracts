// contract: DyBorrow.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVenusBEP20Delegator.sol";
import "./interfaces/IVenusUnitroller.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPancakeRouter.sol";
import "./interfaces/IPriceOracle.sol";

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

contract DyBNBBorrow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // variables, structs and mappings
    uint256 borrowFees;
    uint256 borrowDivisor;
    IVenusUnitroller public rewardController;
    IPriceOracle public oracle;

    uint256 constant BIPS = 1e18;
    address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    mapping(address => address) public delegator;
    mapping(address => mapping(address => uint256)) public borrowingAmount;
    mapping(address => mapping(address => mapping(address => uint256)))
        public underlyingBalanceUser;

    // events

    // constructor and functions
    constructor(
        address rewardController_,
        uint256 borrowFees_,
        uint256 borrowDivisor_,
        address oracle_
    ) {
        rewardController = IVenusUnitroller(rewardController_);
        borrowFees = borrowFees_;
        borrowDivisor = borrowDivisor_;
        oracle = IPriceOracle(oracle_);
    }

    function setDelegator(
        address[] memory _underlyings,
        address[] memory _delegators
    ) public onlyOwner {
        for (uint256 i = 0; i <= _underlyings.length - 1; i++) {
            delegator[_underlyings[i]] = _delegators[i];
        }
        rewardController.enterMarkets(_delegators);
    }

    function setBorrowFee(uint256 _borrowFees) public onlyOwner {
        require(_borrowFees < borrowDivisor, "Fee too high");
        borrowFees = _borrowFees;
    }

    function borrow(
        uint256 _amount,
        address underlying_,
        address borrowToken_
    )
        public
        // uint256 _borrowAmount
        nonReentrant
    {
        require(
            delegator[underlying_] != address(0) &&
                delegator[borrowToken_] != address(0),
            "[DyBEP20BorrowVenus]::Underlying is not registered."
        );

        IERC20 underlying = IERC20(underlying_);
        IERC20 borrowUnderlying = IERC20(borrowToken_);
        IVenusBEP20Delegator tokenDelegator = IVenusBEP20Delegator(
            delegator[underlying_]
        );
        IVenusBEP20Delegator borrowDelegator = IVenusBEP20Delegator(
            delegator[borrowToken_]
        );

        // Supplying underlying
        underlying.transferFrom(_msgSender(), address(this), _amount);
        underlying.approve(address(tokenDelegator), _amount);

        require(
            tokenDelegator.mint(_amount) == 0,
            "[DyBEP20BorrowVenus]::Supplying failed"
        );

        // Borrowing
        uint256 borrowableAmount = getBorrowableAmount(borrowToken_);

        require(
            borrowDelegator.borrow(borrowableAmount) == 0,
            "[DyBEP20BorrowVenus]::Borrowing failed"
        );

        uint256 borrowedAmount = borrowUnderlying.balanceOf(address(this));

        borrowUnderlying.transfer(_msgSender(), borrowedAmount);

        borrowingAmount[_msgSender()][borrowToken_] += borrowedAmount;
        underlyingBalanceUser[_msgSender()][underlying_][
            borrowToken_
        ] += _amount;
    }

    function repay(
        uint256 _amount,
        address underlying_,
        address borrowToken_
    ) public nonReentrant {
        require(
            delegator[underlying_] != address(0) &&
                delegator[borrowToken_] != address(0),
            "[DyBEP20BorrowVenus]::Underlying is not registered."
        );

        IERC20 underlying = IERC20(underlying_);
        IERC20 borrowUnderlying = IERC20(borrowToken_);
        IVenusBEP20Delegator tokenDelegator = IVenusBEP20Delegator(
            delegator[underlying_]
        );
        IVenusBEP20Delegator borrowDelegator = IVenusBEP20Delegator(
            delegator[borrowToken_]
        );

        // Repay borrowing
        borrowUnderlying.transferFrom(_msgSender(), address(this), _amount);
        borrowUnderlying.approve(address(borrowDelegator), _amount);

        require(
            borrowDelegator.repayBorrow(_amount) == 0,
            "[DyBEP20BorrowVenus]::Repay failed"
        );

        borrowingAmount[_msgSender()][borrowToken_] = borrowingAmount[
            _msgSender()
        ][borrowToken_].sub(_amount);

        // Redeem underlying if satisfy repay condition

        if (borrowingAmount[_msgSender()][borrowToken_] == 0) {
            uint256 underlyingBalanceAmount = underlyingBalanceUser[
                _msgSender()
            ][underlying_][borrowToken_];

            uint256 redeemableUnderlying = getRedeemableAmount(underlying_);

            require(
                redeemableUnderlying > 0,
                "[DyBEP20BorrowVenus]::Not enough redeemable assets"
            );

            uint256 finalRedeemableAmount = 0;
            if (
                redeemableUnderlying <=
                underlyingBalanceAmount.mul(borrowDivisor.sub(borrowFees)).div(
                    borrowDivisor
                )
            ) {
                finalRedeemableAmount = redeemableUnderlying;
            } else {
                finalRedeemableAmount = underlyingBalanceAmount
                    .mul(borrowDivisor.sub(borrowFees))
                    .div(borrowDivisor);
            }

            uint256 success = tokenDelegator.redeemUnderlying(
                finalRedeemableAmount
            );
            require(success == 0, "[DyBEP20BorrowVenus]::Failed to redeem");

            uint256 redeemedUnderlyingBalance = underlying.balanceOf(
                address(this)
            );
            underlying.transfer(_msgSender(), redeemedUnderlyingBalance);
            underlyingBalanceUser[_msgSender()][underlying_][borrowToken_] = 0;
        }
    }

    function getBorrowBalance(address borrowToken_)
        public
        view
        returns (uint256)
    {
        return borrowingAmount[_msgSender()][borrowToken_];
    }

    // private functions

    function getBorrowableAmount(address borrowToken_)
        public
        view
        returns (uint256)
    {
        IVenusBEP20Delegator borrowDelegator = IVenusBEP20Delegator(
            delegator[borrowToken_]
        );

        (
            uint256 errorCode,
            uint256 borrowableAmountInDollar,
            uint256 shortFall
        ) = rewardController.getAccountLiquidity(address(this));
        require(errorCode == 0, "[DyBEP20BorrowVenus]::Get borrowable failed");
        require(
            shortFall == 0,
            "[DyBEP20BorrowVenus]::Having shortfall account"
        );

        uint256 underlyingPrice = oracle.getUnderlyingPrice(
            delegator[borrowToken_]
        );

        (, uint256 borrowLimit) = rewardController.markets(
            address(borrowDelegator)
        );

        return
            borrowableAmountInDollar
                .mul(underlyingPrice)
                .div(BIPS)
                .mul(borrowLimit)
                .div(BIPS);
    }

    function getRedeemableAmount(address underlying_)
        private
        returns (uint256)
    {
        IVenusBEP20Delegator tokenDelegator = IVenusBEP20Delegator(
            delegator[underlying_]
        );
        uint256 underlyingBalance = tokenDelegator.balanceOfUnderlying(
            address(this)
        );
        uint256 borrowed = tokenDelegator.borrowBalanceCurrent(address(this));

        (, uint256 borrowLimit) = rewardController.markets(
            address(tokenDelegator)
        );

        uint256 redeemSafeteMargin = BIPS.mul(990).div(1000);

        return
            underlyingBalance
                .sub(borrowed.mul(BIPS).div(borrowLimit))
                .mul(redeemSafeteMargin)
                .div(BIPS);
    }
}
