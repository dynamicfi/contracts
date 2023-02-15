// contract: DyBorrow.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IVenusBNBDelegator.sol";

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

contract MiddleProtocol {
    address borrowContract;

    modifier isBorrowContract() {
        require(
            borrowContract == msg.sender,
            "[DyBEP20BorrowVenus]::Must be borrow contract"
        );
        _;
    }

    constructor(address borrowContract_) {
        borrowContract = borrowContract_;
    }

    function supplyBNB(address delegator_, uint256 amount_)
        public
        payable
        isBorrowContract
    {
        IVenusBNBDelegator bnbDelegator = IVenusBNBDelegator(delegator_);
        bnbDelegator.mint{value: amount_}();
    }

    function redeemBNB(
        address delegator_,
        uint256 amount_,
        address withdrawer_
    ) public payable isBorrowContract {
        IVenusBNBDelegator bnbDelegator = IVenusBNBDelegator(delegator_);

        uint256 success = bnbDelegator.redeemUnderlying(amount_);
        require(success == 0, "[DyBEP20BorrowVenus]::Failed to redeem");
        (bool transferSuccess, ) = withdrawer_.call{
            value: address(this).balance
        }("");
        require(transferSuccess, "Transfer ETH failed");
    }

    receive() external payable {}
}
