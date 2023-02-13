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

interface IERC20Decimal {
    function decimals() external view returns (uint256);
}

contract DyBNBBorrow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // variables, structs and mappings
    uint256 borrowFees;
    uint256 borrowDivisor;
    IVenusUnitroller public rewardController;
    IPriceOracle public oracle;

    uint256 constant BIPS = 1e18;
    uint256 constant ONE_YEAR_IN_SECOND = 365 days;
    address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    uint256 constant Divident = 10000;
    address[] vaults;

    mapping(address => address) public delegator;
    mapping(address => mapping(address => uint256)) public borrowingAmount;
    mapping(address => mapping(address => uint256))
        public underlyingBalanceUser;
    mapping(address => mapping(address => uint256)) public borrowTimestamp;
    mapping(address => uint256) public BorrowAPY;

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
            vaults.push(_underlyings[i]);
        }
        rewardController.enterMarkets(_delegators);
    }

    function setAPY(uint256 APY_, address token_) public onlyOwner {
        BorrowAPY[token_] = APY_;
    }

    function setBorrowFee(uint256 _borrowFees) public onlyOwner {
        require(_borrowFees < borrowDivisor, "Fee too high");
        borrowFees = _borrowFees;
    }

    function removeVault(uint256 index_) public onlyOwner {
        require(index_ < vaults.length, "[DyBEP20BorrowVenus]::Invalid index");
        rewardController.exitMarket(vaults[index_]);
        delete vaults[index_];
    }

    function deposit(
        uint256 amount_,
        address depositor_,
        address underlying_
    ) public {
        require(
            delegator[underlying_] != address(0),
            "[DyBEP20BorrowVenus]::Underlying is not registered."
        );

        IERC20 underlying = IERC20(underlying_);
        IVenusBEP20Delegator tokenDelegator = IVenusBEP20Delegator(
            delegator[underlying_]
        );

        // Supplying underlying
        underlying.transferFrom(_msgSender(), address(this), amount_);
        underlying.approve(address(tokenDelegator), amount_);

        require(
            tokenDelegator.mint(amount_) == 0,
            "[DyBEP20BorrowVenus]::Supplying failed"
        );

        underlyingBalanceUser[depositor_][underlying_] += amount_;
    }

    function withdraw(
        uint256,
        address withdrawer_,
        address underlying_
    ) public {
        require(
            delegator[underlying_] != address(0),
            "[DyBEP20BorrowVenus]::Underlying is not registered."
        );

        require(
            checkCanWithdraw(withdrawer_) == true,
            "[DyBEP20BorrowVenus]::Need to pay borrowed"
        );

        IERC20 underlying = IERC20(underlying_);
        IVenusBEP20Delegator tokenDelegator = IVenusBEP20Delegator(
            delegator[underlying_]
        );

        // Redeem underlying if satisfy repay condition

        uint256 underlyingBalanceAmount = underlyingBalanceUser[withdrawer_][
            underlying_
        ];

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

        uint256 redeemedUnderlyingBalance = underlying.balanceOf(address(this));
        underlying.transfer(withdrawer_, redeemedUnderlyingBalance);
        underlyingBalanceUser[withdrawer_][underlying_] = underlyingBalanceUser[
            withdrawer_
        ][underlying_].sub(underlyingBalanceUser[withdrawer_][underlying_]);
    }

    function borrow(uint256 _amount, address borrowToken_) public nonReentrant {
        IERC20 borrowUnderlying = IERC20(borrowToken_);
        IVenusBEP20Delegator borrowDelegator = IVenusBEP20Delegator(
            delegator[borrowToken_]
        );

        // Borrowing
        uint256 borrowableAmount = getUserBorrowableAmount(
            _msgSender(),
            borrowToken_
        );

        require(
            _amount <= borrowableAmount,
            "[DyBEP20BorrowVenus]::Exceed borrowable amount"
        );

        require(
            borrowDelegator.borrow(_amount) == 0,
            "[DyBEP20BorrowVenus]::Borrowing failed"
        );

        borrowUnderlying.transfer(_msgSender(), _amount);

        borrowingAmount[_msgSender()][borrowToken_] += _amount;
        borrowTimestamp[_msgSender()][borrowToken_] = block.timestamp;
    }

    function repay(uint256 _amount, address borrowToken_) public nonReentrant {
        require(
            delegator[borrowToken_] != address(0),
            "[DyBEP20BorrowVenus]::Underlying is not registered."
        );

        IERC20 borrowUnderlying = IERC20(borrowToken_);
        IVenusBEP20Delegator borrowDelegator = IVenusBEP20Delegator(
            delegator[borrowToken_]
        );

        uint256 interest = getBorrowInterest(_msgSender(), borrowToken_);
        uint256 totalAmount = interest + _amount;

        // Repay borrowing
        borrowUnderlying.transferFrom(_msgSender(), address(this), totalAmount);
        borrowUnderlying.approve(address(borrowDelegator), totalAmount);

        require(
            borrowDelegator.repayBorrow(totalAmount) == 0,
            "[DyBEP20BorrowVenus]::Repay failed"
        );

        borrowingAmount[_msgSender()][borrowToken_] = borrowingAmount[
            _msgSender()
        ][borrowToken_].sub(_amount);
    }

    function getBorrowBalance(address borrowToken_)
        public
        view
        returns (uint256)
    {
        return borrowingAmount[_msgSender()][borrowToken_];
    }

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

    function getUserBorrowableAmount(address user_, address borrowToken_)
        public
        view
        returns (uint256)
    {
        IVenusBEP20Delegator borrowDelegator = IVenusBEP20Delegator(
            delegator[borrowToken_]
        );

        uint256 underlyingInDollars = 0;
        uint256 borrowInDollars = 0;
        for (uint256 i = 0; i < vaults.length; i++) {
            address tokenAddress = vaults[i];
            uint256 tokenPrice = oracle.getUnderlyingPrice(
                delegator[tokenAddress]
            );
            underlyingInDollars = underlyingInDollars.add(
                underlyingBalanceUser[user_][vaults[i]].mul(BIPS).div(
                    tokenPrice
                )
            );
            borrowInDollars = borrowInDollars.add(
                borrowingAmount[user_][vaults[i]].mul(BIPS).div(tokenPrice)
            );
        }

        uint256 borrowableAmountInDollar = underlyingInDollars.sub(
            borrowInDollars
        );

        uint256 underlyingPrice = oracle.getUnderlyingPrice(
            delegator[borrowToken_]
        );

        (, uint256 borrowLimit) = rewardController.markets(
            address(borrowDelegator)
        );

        uint256 userBorrowableAmountRaw = borrowableAmountInDollar
            .mul(underlyingPrice)
            .div(BIPS)
            .mul(borrowLimit)
            .div(BIPS);
        uint256 borrowableAmountRaw = getBorrowableAmount(borrowToken_);
        if (userBorrowableAmountRaw > borrowableAmountRaw) {
            return borrowableAmountRaw;
        }
        return userBorrowableAmountRaw;
    }

    function getBorrowedAmount(address user_, address borrowToken_)
        public
        view
        returns (uint256)
    {
        return borrowingAmount[user_][borrowToken_];
    }

    function getRealBorrowableAmount(uint256 amount_, address borrowToken_)
        public
        view
        returns (uint256)
    {
        IERC20Decimal borrowInterface = IERC20Decimal(borrowToken_);
        return
            amount_
                .mul(borrowInterface.decimals())
                .div(10**(18 - borrowInterface.decimals()))
                .div(BIPS);
    }

    function getBorrowInterest(address user_, address borrowToken_)
        public
        view
        returns (uint256)
    {
        uint256 borrowAmount = borrowingAmount[user_][borrowToken_];
        return
            (block.timestamp - borrowTimestamp[user_][borrowToken_])
                .mul(borrowAmount)
                .mul(BorrowAPY[borrowToken_])
                .div(ONE_YEAR_IN_SECOND)
                .div(Divident);
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

    function getVaults() public view returns (address[] memory vaults_) {
        vaults_ = new address[](vaults.length);
        for (uint256 i = 0; i < vaults.length; i++) {
            vaults_[i] = vaults[i];
        }
        return vaults_;
    }

    function checkCanWithdraw(address user_) public view returns (bool) {
        for (uint256 i = 0; i < vaults.length; i++) {
            if (borrowingAmount[user_][vaults[i]] > 0) {
                return false;
            }
        }
        return true;
    }
}
