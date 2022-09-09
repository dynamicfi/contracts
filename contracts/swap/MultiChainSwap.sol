// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./UniswapInterface.sol";

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
    uint256 constant swapTimeout = 900;
    uint256 public fee;
    address public cbridgeAddress; // 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
    mapping(address => bool) public zeroFee;
    address public router;
    address public WETH;
    
    function initialize(address _cbridgeAddress, uint256 _fee, address _router, address _weth) public initializer 
    {
        cbridgeAddress = _cbridgeAddress;
        router = _router;
        fee = _fee;
        WETH = _weth;
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
        address _tokenFrom,
        address _tokenTo,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage)
        external payable
    {

        bool result = IERC20(_tokenFrom).transferFrom(msg.sender, address(this), _amount);
        require(result, "token transfer fail");

        uint256 amountOut = 0;
        if(msg.value >0) {
            uint256 remainingAmount = msg.value;
            if(!zeroFee[msg.sender] && fee > 0) {
                uint256 totalFee = fee * _amount / divider;
                remainingAmount -= totalFee;
            }
            appove(router, _tokenFrom, remainingAmount);
            address[] memory path;
            path = new address[](2);
            path[0] = WETH;
            path[1] = _tokenTo;
            amountOut = IUniswapV2Router(router).getAmountsOut(remainingAmount, path);
            require(amountOut > 0, "Invalid param");
            uint256[] memory amounts = IUniswapV2Router(router).swapETHForExactTokens{value: _remainingAmount}(amountOut, path, address(this), block.timestamp + swapTimeout);
            amountOut = amounts[2];
        } else {
            uint256 remainingAmount = _amount;
            if(!zeroFee[msg.sender] && fee > 0) {
                uint256 totalFee = fee * _amount / divider;
                remainingAmount -= totalFee;
            }
            appove(router, _tokenFrom, remainingAmount);
            if(_tokenFrom != _tokenTo) {
                address[] memory path;
                if (_tokenFrom == WETH || _tokenTo == WETH) {
                    path = new address[](2);
                    path[0] = _tokenFrom;
                    path[1] = _tokenTo;
                } else {
                    path = new address[](3);
                    path[0] = _tokenFrom;
                    path[1] = WETH;
                    path[2] = _tokenTo;
                }
                
                amountOut = IUniswapV2Router(router).getAmountsOut(remainingAmount, path);
                require(amountOut > 0, "Invalid param");
                    uint256[] memory amounts = IUniswapV2Router(router).swapExactTokensForTokens(remainingAmount, amountOut, path, address(this), block.timestamp + swapTimeout);
                amountOut = amounts[2];
            } else {
                amountOut = remainingAmount;
            }
        }

        appove(cbridgeAddress, _tokenTo, amountOut);
        ICbridge(cbridgeAddress).send(_receiver, _token, amountOut, _dstChainId, _nonce, _maxSlippage);
    }

    function appove(address spener, address token, uint256 amount) internal {
        if(IERC20(token).allowance(address(this), spener)< amount) {
            IERC20(token).approve(spener, amount);
        }
    }
}