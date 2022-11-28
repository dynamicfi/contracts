// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

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

contract Dynamic is
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20BurnableUpgradeable
{
    uint256 totalLocked;

    event Lock(uint256 amount);
    event Unlock(uint256 amount);

    // constructor() ERC20("Dynamic", "DYNA") {
    //     _mint(_msgSender(), 400000 * 10**18);
    // }

    function mint(uint256 _amount) public onlyOwner {
        _mint(_msgSender(), _amount);
    }

    function burn(uint256 _amount) public override onlyOwner {
        _burn(_msgSender(), _amount);
    }

    function lock(uint256 _amount) public onlyOwner {
        super.transferFrom(_msgSender(), address(this), _amount);
        totalLocked += _amount;
        emit Lock(_amount);
    }

    function unlock(uint256 _amount) public onlyOwner {
        require(totalLocked >= _amount, "[DYNA]: Not enough token locked");
        super.transfer(_msgSender(), _amount);
        totalLocked -= _amount;
        emit Unlock(_amount);
    }
}
