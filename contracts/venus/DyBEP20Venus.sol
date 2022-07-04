// contracts/DyERC20.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../DyERC20.sol";
import "./interfaces/ITokenVenus.sol";

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

contract DyBEP20Venus is DyERC20 {
    using SafeERC20 for IERC20;

    address public tokenDelegator;

    event Failure(uint256 code, string info);

    constructor(
        address underlying_,
        string memory name_,
        string memory symbol_,
        address tokenDelegator_
    ) DyERC20(underlying_, name_, symbol_) {
        underlying = underlying_;
        tokenDelegator = tokenDelegator_;
    }

    function totalDeposits() public view virtual override returns (uint256) {
        return IERC20(underlying).balanceOf(address(this));
    }

    function _stakeDepositTokens(uint256 amountUnderlying_)
        internal
        virtual
        override
    {
        require(amountUnderlying_ > 0, "DyBEP20Venus::stakeDepositTokens");
        IERC20(underlying).approve(address(tokenDelegator), amountUnderlying_);
        ITokenVenus(tokenDelegator).mint(amountUnderlying_);
    }

    function _withdrawDepositTokens(uint256 amountUnderlying_)
        internal
        virtual
        override
    {
        uint256 error = ITokenVenus(tokenDelegator).redeemUnderlying(amountUnderlying_);
        if (error != 0) {
            emit Failure(error, "DyBEP20Venus::withdrawDepositTokens");
        }
    }
}
