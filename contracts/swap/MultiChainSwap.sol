// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ICbridge {
    function send (
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage // slippage * 1M, eg. 0.5% -> 5000
    )external;
}
contract CrossChain is UUPSUpgradeable, OwnableUpgradeable {
    uint256 constant divider = 10000;
    uint256 public fee;
    address public cbridgeAddress;
    mapping(address => bool) public zeroFee;
    
    function initialize(address _cbridgeAddress, uint256 _fee) public initializer 
    {
        cbridgeAddress = _cbridgeAddress;
        fee = _fee;
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function updateFee(uint256 _fee) public onlyOwner{
        fee = _fee;
    }
    function updateBridgeContract(address _cbridgeAddress) public onlyOwner{
        cbridgeAddress = _cbridgeAddress;
    }

    function setFreeFee(address _target, bool _isFreeFee) public onlyOwner {
        zeroFee[_target] = _isFreeFee;
    }

    function swap(address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage)
        external
    {
        bool result = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(result, "token transfer fail");

        uint256 remainingAmount = _amount;
        if(!zeroFee[msg.sender] && fee > 0) {
            uint256 totalFee = fee * _amount / divider;
            remainingAmount -= totalFee;
        }
        
        appove(_token, remainingAmount);
        ICbridge(cbridgeAddress).send(_receiver, _token, remainingAmount, _dstChainId, _nonce, _maxSlippage);
    }

    function appove(address token, uint256 amount) internal {
        if(IERC20(token).allowance(address(this), cbridgeAddress)< amount) {
            IERC20(token).approve(cbridgeAddress, amount);
        }
    }
}