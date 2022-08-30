// contracts/DyETH.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./DyToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

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

abstract contract DyETH is DyToken, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function deposit(uint256 amountUnderlying_) external nonReentrant payable {
        _deposit(amountUnderlying_);
    }

    function withdraw(uint256 amount_) external nonReentrant {
        _withdraw(amount_);
    }

    function _doTransferIn(address from_, uint256 amount_) virtual override internal {
        require(_msgSender() == from_, "sender mismatch");
        require(msg.value == amount_, "value mismatch");
    }

    function _doTransferOut(address payable to_, uint256 amount_) virtual override internal {
        to_.transfer(amount_);
    }
}