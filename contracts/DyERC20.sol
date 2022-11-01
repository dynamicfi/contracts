// contracts/DyERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DyToken.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

abstract contract DyERC20 is DyToken {
    IERC20 public underlying;
    uint256[] public totalValues = [
        0,
        1000000,
        10000000,
        100000000,
        1000000000
    ]; // for total value in dollar

    uint256[] public percentByValues = [80, 65, 50, 35, 20];
    uint256 totalTokenStack = 0;
    uint256 ONE_MONTH_IN_SECONDS = 30 days;

    constructor(
        address underlying_,
        string memory name_,
        string memory symbol_
    ) DyToken(name_, symbol_) {
        underlying = IERC20(underlying_);
    }

    function deposit(uint256 amountUnderlying_) public virtual {
        DepositStruct storage user = userInfo[_msgSender()];
        if (!user.enable) {
            depositors.push(_msgSender());
            user.enable = true;
        }

        user.amount += amountUnderlying_;
        user.lastDepositTime = block.timestamp;
        totalTokenStack += amountUnderlying_;

        _deposit(amountUnderlying_);
    }

    function withdraw(uint256 amount_) public virtual {
        DepositStruct storage user = userInfo[_msgSender()];
        require(user.enable, "DyToken:: Need to initial account");
        require(user.amount >= amount_, "DyToken:: Not enough balance");

        user.amount -= amount_;
        user.lastDepositTime = block.timestamp;
        totalTokenStack -= amount_;

        _withdraw(amount_);
    }

    function claimDyna(uint256 amount_) external {
        _claimDyna(amount_);
    }

    function getDyna() external view returns (uint256) {
        return _getDynaBalance();
    }

    function _doTransferIn(address from_, uint256 amount_)
        internal
        virtual
        override
    {
        require(
            underlying.transferFrom(from_, address(this), amount_),
            "DyERC20::_doTransferIn"
        );
    }

    function _doTransferOut(address payable to_, uint256 amount_)
        internal
        virtual
        override
    {
        require(underlying.transfer(to_, amount_), "DyERC20::_doTransferOut");
    }
}
