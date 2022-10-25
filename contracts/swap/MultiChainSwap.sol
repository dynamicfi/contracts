// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniswapInterface.sol";
import "./SafeMath.sol";

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

// interface ICbridge {
//     function send (
//         address _receiver,
//         address _token,
//         uint256 _amount,
//         uint64 _dstChainId,
//         uint64 _nonce,
//         uint32 _maxSlippage // slippage * 1M, eg. 0.5% -> 5000
//     )external;
// }

contract CrossChain is Ownable {
    // variables and mappings
    using SafeMath for uint256;
    uint256 constant divider = 10000;
    uint256 constant swapTimeout = 900;
    uint256 public fee;
    // address public cbridgeAddress; // 0xf89354F314faF344Abd754924438bA798E306DF2
    address public router; // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    address public WETH;
    mapping(address => bool) public zeroFee;

    // structs and events
    event SwapForToken(
        address receiver,
        address tokenTo,
        uint256 amount,
        uint256 chainId
    );

    constructor(
        // address _cbridgeAddress,
        uint256 _fee,
        address _router,
        address _weth
    ) {
        // cbridgeAddress = _cbridgeAddress;
        router = _router;
        fee = _fee;
        WETH = _weth;
    }

    function updateFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    // function updateBridgeContract(address _cbridgeAddress) public onlyOwner {
    //     cbridgeAddress = _cbridgeAddress;
    // }

    function setFreeFee(address _target, bool _isFreeFee) public onlyOwner {
        zeroFee[_target] = _isFreeFee;
    }

    function swap(
        address _receiver,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amount,
        uint64 _dstChainId // uint64 _nonce, // uint32 _maxSlippage
    ) external payable {
        uint256 amountOut = 0;
        if (msg.value > 0) {
            uint256 remainingAmount = msg.value;
            if (!zeroFee[msg.sender] && fee > 0) {
                uint256 totalFee = (fee * _amount) / divider;
                remainingAmount = remainingAmount.sub(totalFee);
            }
            appove(router, _tokenFrom, remainingAmount);
            address[] memory path;
            path = new address[](2);
            path[0] = WETH;
            path[1] = _tokenTo;
            uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                remainingAmount,
                path
            );
            require(amt[2] > 0, "Invalid param");
            uint256[] memory amounts = IUniswapV2Router(router)
                .swapETHForExactTokens{value: remainingAmount}(
                amountOut,
                path,
                address(this),
                block.timestamp + swapTimeout
            );
            amountOut = amounts[2];
        } else {
            bool result = IERC20(_tokenFrom).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            require(result, "token transfer fail");

            uint256 remainingAmount = _amount;
            if (!zeroFee[msg.sender] && fee > 0) {
                uint256 totalFee = (fee * _amount) / divider;
                remainingAmount = remainingAmount.sub(totalFee);
            }
            appove(router, _tokenFrom, remainingAmount);
            if (_tokenFrom != _tokenTo) {
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

                uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                    remainingAmount,
                    path
                );
                require(amt[2] > 0, "Invalid param");
                uint256[] memory amounts = IUniswapV2Router(router)
                    .swapExactTokensForTokens(
                        remainingAmount,
                        amountOut,
                        path,
                        address(this),
                        block.timestamp + swapTimeout
                    );
                amountOut = amounts[2];
            } else {
                amountOut = remainingAmount;
            }
        }

        emit SwapForToken(_receiver, _tokenTo, amountOut, _dstChainId);

        // appove(cbridgeAddress, _tokenTo, amountOut);
        // ICbridge(cbridgeAddress).send(
        //     _receiver,
        //     _tokenTo,
        //     amountOut,
        //     _dstChainId,
        //     _nonce,
        //     _maxSlippage
        // );
    }

    function appove(
        address spener,
        address token,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spener) < amount) {
            IERC20(token).approve(spener, amount);
        }
    }
}
