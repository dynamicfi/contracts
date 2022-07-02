// contracts/TestToken.sol
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20
{

    constructor() ERC20("TESTToken", "TT") {
        _mint(_msgSender(), 1000000000000000000000000);
    }
}