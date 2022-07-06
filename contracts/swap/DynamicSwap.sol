// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniswapInterface.sol";

contract DynamicSwap is Ownable {
    using SafeERC20 for IERC20;
    // address private constant UNISWAP_V2_ROUTER =
    //     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // address private immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private immutable WETH;
    address private immutable ROUTER;
    uint256 private _fee;

    constructor(
        address router_,
        address weth_,
        uint256 fee_
    ) {
        ROUTER = router_;
        WETH = weth_;
        _fee = fee_;
    }

    receive() external payable {}

    function swapTokenForToken(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address to_,
        uint256 deadline_
    ) external {
        IERC20(tokenIn_).transferFrom(msg.sender, address(this), amountIn_);
        IERC20(tokenIn_).approve(ROUTER, amountIn_);

        address[] memory path;
        if (tokenIn_ == WETH || tokenOut_ == WETH) {
            path = new address[](2);
            path[0] = tokenIn_;
            path[1] = tokenOut_;
        } else {
            path = new address[](3);
            path[0] = tokenIn_;
            path[1] = WETH;
            path[2] = tokenOut_;
        }

        IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            amountIn_,
            amountOutMin_,
            path,
            to_,
            deadline_
        );
    }

    function swapEthForToken(
        uint256 amountOutMin_,
        address[] calldata path_,
        address to_,
        uint256 deadline_
    ) external payable {
        (bool success, ) = ROUTER.call{value: msg.value}(
            abi.encodeWithSignature(
                "swapExactETHForTokens(uint256 amountOutMin,address[] calldata path,address to,uint256 deadline)",
                amountOutMin_,
                path_,
                to_,
                deadline_
            )
        );
        require(success, "transaction failed");
    }

    function swapTokenForEth(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_,
        address to_,
        uint256 deadline_
    ) external {
        (bool success, ) = ROUTER.call(
            abi.encodeWithSignature(
                "swapExactTokensForETH(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline)",
                amountIn_,
                amountOutMin_,
                path_,
                to_,
                deadline_
            )
        );
        require(success, "transaction failed");
    }

    function claimToken(address token_, address receipt_) public onlyOwner {
        IERC20(token_).safeTransfer(
            receipt_,
            IERC20(token_).balanceOf(address(this))
        );
    }
}
