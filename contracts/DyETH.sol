// contracts/DyETH.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./DyToken.sol";
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

abstract contract DyETH is DyToken, ReentrancyGuard {
    using SafeERC20 for IERC20;
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

    constructor(string memory name_, string memory symbol_)
        DyToken(name_, symbol_)
    {}

    function deposit(uint256 amountUnderlying_)
        public
        payable
        virtual
        nonReentrant
    {
        _deposit(amountUnderlying_);
    }

    function withdraw(uint256 amount_) public virtual nonReentrant {
        _withdraw(amount_);
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
