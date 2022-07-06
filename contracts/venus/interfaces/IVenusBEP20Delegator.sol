// contracts/venus/ITokenVenus.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

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

interface IVenusBEP20Delegator {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);
    
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint);
}
