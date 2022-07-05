// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./UniswapInterface.sol";

contract DynamicSwap {
    using SafeERC20 for IERC20;
    // address private constant UNISWAP_V2_ROUTER =
    //     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // address private immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private immutable WETH;
    address private immutable ROUTER;

    constructor(address router_, address weth_) {
        ROUTER = router_;
        WETH = weth_;
    }

    receive() external payable {}

    function swapTokenForToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external {
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).approve(ROUTER, _amountIn);

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

    function swapEthForToken(
        address _router,
        address _tokenOut,
        uint256 _amountOutMin,
        address _to
    ) external payable {
        address[] memory path;
        path[0] = _tokenOut;

        (bool success, ) = _router.call{value: msg.value}(
            abi.encodeWithSignature(
                "swapExactETHForTokens(uint256 amountOutMin,address[] calldata path,address to,uint256 deadline)",
                _amountOutMin,
                path,
                _to,
                block.timestamp
            )
        );
        require(success, "transaction failed");
    }

    function swapTokenForEth(
        address _router,
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external payable {
        address[] memory path;
        path[0] = _tokenIn;

        (bool success, ) = _router.call{value: msg.value}(
            abi.encodeWithSignature(
                "swapExactTokensForETH(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline)",
                _amountIn,
                _amountOutMin,
                path,
                _to,
                block.timestamp
            )
        );
        require(success, "transaction failed");
    }
}
