// contracts/DyERC20.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./DyToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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
    using SafeERC20 for IERC20;
    IERC20 public underlying;

    constructor(address underlying_, string memory name_, string memory symbol_) DyToken(name_, symbol_) {
        underlying = IERC20(underlying_);
    }

    function _doTransferIn(address from_, uint amount_) virtual override internal {
        IERC20(underlying).safeTransferFrom(
            from_,
            address(this),
            amount_
        );
    }

    function _doTransferOut(address payable to_, uint amount_) virtual override internal {
        IERC20(underlying).safeTransferFrom(
            address(this),
            to_,
            amount_
        );
    }
}