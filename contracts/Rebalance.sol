// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IDyLending {
    function reinvest() external;
}

contract Rebalance is Ownable {
    struct LendingData {
        address contractAddr;
        bool isActive;
    }

    LendingData[] public lendings;

    constructor(address[] memory lendingAddrs) {
        for (uint256 i = 0; i < lendingAddrs.length; i++) {
            lendings.push(LendingData(lendingAddrs[i], true));
        }
    }

    function addLending(address lendingAddr_) external onlyOwner {
        lendings.push(LendingData(lendingAddr_, true));
    }

    function setLendingStatus(uint256 lendingId_, bool newStatus_)
        external
        onlyOwner
    {
        LendingData storage lending = lendings[lendingId_];
        lending.isActive = newStatus_;
    }

    function setLendingAddr(uint256 lendingId_, address newAddress_)
        external
        onlyOwner
    {
        LendingData storage lending = lendings[lendingId_];
        lending.contractAddr = newAddress_;
    }

    function rebalance() public {
        for (uint256 i = 0; i < lendings.length; i++) {
            if (lendings[i].isActive == true) {
                IDyLending(lendings[i].contractAddr).reinvest();
            }
        }
    }

    function rebalance(uint256 from_, uint256 to_) public {
        for (uint256 i = from_; i < to_; i++) {
            if (lendings[i].isActive == true) {
                IDyLending(lendings[i].contractAddr).reinvest();
            }
        }
    }
}
