// contracts/DyERC20.sol
//SPDX-License-Identifier: Unlicense
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

    constructor(address underlying_, string memory name_, string memory symbol_) DyToken(name_, symbol_) {
        underlying = IERC20(underlying_);
    }

    function deposit(uint256 amountUnderlying_) external {
        _deposit(amountUnderlying_);
    }

    function withdraw(uint256 amount_) external {
        _withdraw(amount_);
    }

    function _doTransferIn(address from_, uint amount_) virtual override internal {
       require(underlying.transferFrom(from_, address(this), amount_), "DyERC20::_doTransferIn");
    }

    function _doTransferOut(address payable to_, uint amount_) virtual override internal {
        require(underlying.transfer(to_, amount_), "DyERC20::_doTransferOut");
    }
}