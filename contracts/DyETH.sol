// contracts/DyETH.sol
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./DyToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DyETH is DyToken {
    using SafeERC20 for IERC20;

    constructor(string memory name_, string memory symbol_) DyToken(name_, symbol_) {}

    function _doTransferIn(address from_, uint256 amount_) virtual override internal {
        require(msg.sender == from_, "sender mismatch");
        require(msg.value == amount_, "value mismatch");
    }

    function _doTransferOut(address payable to_, uint256 amount_) virtual override internal {
        to_.transfer(amount_);
    }

    function totalDeposits () virtual override public view returns (uint256) {
        return address(this).balance;
    }
}