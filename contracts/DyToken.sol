// contracts/DyToken.sol
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract DyToken is ERC20 {
    using SafeMath for uint256;

    event Mint(address sender, uint256 amountUnderlying, uint256 amountToken);
    event Redeem(address sender, uint256 amount, uint256 amountUnderlying);

    constructor(string memory name_, string memory symbol_) ERC20 (name_, symbol_) {}

    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount_ deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint256 amount_) public view returns (uint256) {
          if (totalSupply().mul(totalDeposits()) == 0) {
            return amount_;
        }
        return amount_.mul(totalSupply()).div(totalDeposits());
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount_ receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint256 amount_) public view returns (uint256) {
        if (totalSupply().mul(totalDeposits()) == 0) {
            return amount_;
        }
        return amount_.mul(totalDeposits()).div(totalSupply());
    }

    function mint(uint256 amountUnderlying_) external {
        require(amountUnderlying_ > 0, "amountUnderlying_ > 0");
        uint256 _mintTokens = getSharesForDepositTokens(amountUnderlying_);
        _doTransferIn(_msgSender(), amountUnderlying_);
        _mint(_msgSender(), _mintTokens);
        emit Mint(_msgSender(), amountUnderlying_, _mintTokens);
    }

    function redeem(uint256 amount_) external {
        require(amount_ > 0, "amount_ > 0");
        _burn(_msgSender(), amount_);
        uint256 _amountUnderlying = getDepositTokensForShares(amount_);
        _doTransferOut(payable(_msgSender()), _amountUnderlying);
        
        emit Redeem(_msgSender(), amount_, _amountUnderlying);
    }

    function totalDeposits() virtual public view returns (uint256);

    function _doTransferIn(address from_, uint256 amount_) virtual internal;

    function _doTransferOut(address payable to_, uint256 amount_) virtual internal;

}
