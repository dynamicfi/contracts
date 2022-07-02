// contracts/DyERC20.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./DyToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DyERC20 is DyToken {
    using SafeERC20 for IERC20;
    address public underlying;

    constructor(address underlying_, string memory name_, string memory symbol_) DyToken(name_, symbol_) {
        underlying = underlying_;
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

    function totalDeposits () virtual override public view returns (uint256) {
        return IERC20(underlying).balanceOf(address(this));
    }
}