// contracts/DyToken.sol
// SPDX-License-Identifier: MIT
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

abstract contract DyTokenNonUpgradeable is ERC20, Ownable {
    using SafeMath for uint256;

    bool public depositEnable;
    uint256 public minTokensToReinvest;
    mapping(address => uint256) public depositAverageRate;
    address[] public depositors;
    address public DYNA;
    address public USD;

    struct DepositStruct {
        uint256 amount;
        uint256 lastDepositTime;
        uint256 dynaBalance;
        bool enable;
    }

    mapping(address => DepositStruct) public userInfo;

    event Deposit(
        address sender,
        uint256 amountUnderlying,
        uint256 amountToken
    );
    event Withdraw(address sender, uint256 amount);
    event DepositsEnabled(bool newValue);
    event Reinvest(uint256 newTotalDeposits, uint256 newTotalSupply);
    event UpdateMinTokensToReinvest(uint256 oldValue, uint256 newValue);

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

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
     * @notice Update reinvest min threshold
     * @param newValue_ threshold
     */
    function updateMinTokensToReinvest(uint256 newValue_) public onlyOwner {
        emit UpdateMinTokensToReinvest(minTokensToReinvest, newValue_);
        minTokensToReinvest = newValue_;
    }

    /**
     * @notice Sender supplies assets into the market and receives dyTokens in exchange
     * @param amountUnderlying_ The amount of the underlying asset to supply
     */
    function _deposit(uint256 amountUnderlying_) internal {
        require(depositEnable == true, "DyToken::deposit");
        require(amountUnderlying_ > 0, "DyToken::amountUnderlying_ > 0");
        uint256 _mintTokens;
        uint256 _totalDeposit = _totalDepositsFresh();
        uint256 _totalSupply = totalSupply();
        if (_totalDeposit.mul(_totalSupply) == 0) {
            _mintTokens = amountUnderlying_;
        } else {
            _mintTokens = amountUnderlying_.mul(_totalDeposit).div(
                _totalSupply
            );
        }

        // Calculate deposit average exchange rate
        uint256 _userBalance = balanceOf(_msgSender());
        if (_totalDeposit.mul(_totalSupply) == 0) {
            depositAverageRate[_msgSender()] = 1e18;
        }
        if (depositAverageRate[_msgSender()] == 0) {
            depositAverageRate[_msgSender()] = _totalDeposit.mul(1e18).div(
                _totalSupply
            );
        } else {
            uint256 _totalUserDeposit = (
                _userBalance.mul(depositAverageRate[_msgSender()]).div(1e18)
            ).add(amountUnderlying_);
            uint256 _totalToken = _userBalance.add(_mintTokens);
            depositAverageRate[_msgSender()] = (_totalUserDeposit)
                .mul(1e18)
                .div(_totalToken);
        }

        _doTransferIn(_msgSender(), amountUnderlying_);
        _stakeDepositTokens(amountUnderlying_);
        emit Deposit(_msgSender(), amountUnderlying_, _mintTokens);
    }

    /**
     * @notice Sender redeems dyTokens in exchange for the underlying asset
     * @param amount_ The number of dyTokens to redeem into underlying
     */
    function _withdraw(uint256 amount_) internal {
        require(amount_ > 0, "DyToken::amount_ > 0");
        _withdrawDepositTokens(amount_);
        _doTransferOut(payable(_msgSender()), amount_);
        emit Withdraw(_msgSender(), amount_);
    }

    function _claimDyna(uint256 _amount, address _tokenOut) internal {
        DepositStruct storage user = userInfo[_msgSender()];
        require(user.dynaBalance >= _amount, "DyToken::not enough balance");
        user.dynaBalance -= _amount;
        _cashOutDyna(_msgSender(), _amount, _tokenOut);
    }

    function _getDynaBalance() internal view returns (uint256) {
        DepositStruct memory user = userInfo[_msgSender()];
        return user.dynaBalance;
    }

    /**
     * @notice update newest exchange rate and return total deposit
     * @return total underlying tokens
     */
    function _totalDepositsFresh() internal virtual returns (uint256);

    /**
     * @notice Stake underlying asset to a protocol
     * @param amountUnderlying_ The amount of the underlying asset to supply
     */
    function _stakeDepositTokens(uint256 amountUnderlying_) internal virtual;

    /**
     * @notice Withdraw underlying asset from a protocol
     * @param amountUnderlying_ The amount of the underlying asset to supply
     */
    function _withdrawDepositTokens(uint256 amountUnderlying_) internal virtual;

    /**
     * @notice This function returns a snapshot of last available quotes
     * @return total deposits available on the contract
     */
    function totalDeposits() public view virtual returns (uint256);

    /**
     * @dev Performs a transfer in, reverting upon failure.
     *  This may revert due to insufficient balance or insufficient allowance.
     */
    function _doTransferIn(address from_, uint256 amount_) internal virtual;

    /**
     * @dev Performs a transfer out, reverting upon failure.
     */
    function _doTransferOut(address payable to_, uint256 amount_)
        internal
        virtual;

    /**
     * @param _receiver: The receiver cash out dyna
     * @param _amount: Amount of Dyna want to cash out
     * @param _tokenOut: The address of token want to swap out from Dyna
     */
    function _cashOutDyna(
        address _receiver,
        uint256 _amount,
        address _tokenOut
    ) internal virtual;
}
