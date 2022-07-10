// contracts/DyToken.sol
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

abstract contract DyToken is ERC20, Ownable {
    using SafeMath for uint256;

    bool public depositEnable;

    event Deposit(address sender, uint256 amountUnderlying, uint256 amountToken);
    event Withdraw(address sender, uint256 amount, uint256 amountUnderlying, uint256 amountUnderlying1,uint256 amountUnderlying2,uint256 amountUnderlying3);
    event DepositsEnabled(bool newValue);

    constructor(string memory name_, string memory symbol_) ERC20 (name_, symbol_) {}

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) public onlyOwner {
        require(depositEnable != newValue, "DyToken::Value already updated");
        depositEnable = newValue;
        emit DepositsEnabled(newValue);
    }

    /**
     * @notice Sender supplies assets into the market and receives dyTokens in exchange
     * @param amountUnderlying_ The amount of the underlying asset to supply
     */
    function _deposit(uint256 amountUnderlying_) internal {
        require(depositEnable == true, "DyBEP20Venus::deposit");
        require(amountUnderlying_ > 0, "DyToken::amountUnderlying_ > 0");
        uint256 _mintTokens;
        uint256 _totalDeposit = _totalDepositsFresh();
        uint256 _totalSupply = totalSupply();
        if (_totalDeposit.mul(_totalSupply) == 0) {
            _mintTokens = amountUnderlying_;
        } else {
            _mintTokens = amountUnderlying_.mul(_totalDeposit).div(_totalSupply);
        }

        _doTransferIn(_msgSender(), amountUnderlying_);
        _mint(_msgSender(), _mintTokens);
        _stakeDepositTokens(amountUnderlying_);
        emit Deposit(_msgSender(), amountUnderlying_, _mintTokens);
    }

    /**
     * @notice Sender redeems dyTokens in exchange for the underlying asset
     * @param amount_ The number of dyTokens to redeem into underlying
     */
    function _withdraw(uint256 amount_) internal {
        require(amount_ > 0, "DyToken::amount_ > 0");
        uint256 _totalDeposit = _totalDepositsFresh();
        uint256 _totalSupply = totalSupply();
        uint256 _amountUnderlying = _totalDeposit.mul(amount_).div(_totalSupply);
        _burn(_msgSender(), amount_);
        _withdrawDepositTokens(_amountUnderlying);
        _doTransferOut(payable(_msgSender()), _amountUnderlying);
        emit Withdraw(_msgSender(), amount_, _amountUnderlying, _totalDeposit, amount_, _totalSupply);
    }

    /**
     * @notice update newest exchange rate and return total deposit
     * @return total underlying tokens
     */
    function _totalDepositsFresh() virtual internal returns (uint256);

    /**
     * @notice Stake underlying asset to a protocol
     * @param amountUnderlying_ The amount of the underlying asset to supply
     */
    function _stakeDepositTokens(uint256 amountUnderlying_) virtual internal;

    /**
     * @notice Withdraw underlying asset from a protocol
     * @param amountUnderlying_ The amount of the underlying asset to supply
     */
    function _withdrawDepositTokens(uint256 amountUnderlying_) virtual internal;

     /**
     * @notice This function returns a snapshot of last available quotes
     * @return total deposits available on the contract
     */
    function totalDeposits() virtual public view returns (uint256);

    /**
     * @dev Performs a transfer in, reverting upon failure.
     *  This may revert due to insufficient balance or insufficient allowance.
     */
    function _doTransferIn(address from_, uint256 amount_) virtual internal;

    /**
     * @dev Performs a transfer out, reverting upon failure.
     */
    function _doTransferOut(address payable to_, uint256 amount_) virtual internal;

}
