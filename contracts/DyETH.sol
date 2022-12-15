// contracts/DyETH.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DyTokenNonUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

abstract contract DyETH is DyTokenNonUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint256[] public totalValues;
    uint256[] public percentByValues;
    uint256 totalTokenStack;
    uint256 ONE_MONTH_IN_SECONDS;

    constructor(string memory name_, string memory symbol_)
        DyTokenNonUpgradeable(name_, symbol_)
    {
        totalValues = [0, 1000000, 10000000, 100000000, 1000000000]; // for total value in dollar
        percentByValues = [80, 65, 50, 35, 20];
        totalTokenStack = 0;
        ONE_MONTH_IN_SECONDS = 30 days;
    }

    function deposit(uint256 amountUnderlying_)
        public
        payable
        virtual
        nonReentrant
    {
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

    function withdraw(uint256 amount_) public virtual nonReentrant {
        DepositStruct storage user = userInfo[_msgSender()];
        require(user.enable, "DyToken:: Need to initial account");
        require(user.amount >= amount_, "DyToken:: Not enough balance");

        user.amount -= amount_;
        user.lastDepositTime = block.timestamp;
        totalTokenStack -= amount_;

        _withdraw(amount_);
    }

    function claimDyna(uint256 amount_, address _tokenOut) external {
        _claimDyna(amount_, _tokenOut);
    }

    function getDyna() external view returns (uint256) {
        return _getDynaBalance();
    }

    function _doTransferIn(address from_, uint256 amount_)
        internal
        virtual
        override
    {
        require(_msgSender() == from_, "sender mismatch");
        require(msg.value == amount_, "value mismatch");
    }

    function _doTransferOut(address payable to_, uint256 amount_)
        internal
        virtual
        override
    {
        to_.transfer(amount_);
    }
}
