// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniswapInterface.sol";

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

contract DynamicSwap is Ownable {
    using SafeERC20 for IERC20;
    address private immutable WETH;
    address private immutable ROUTER;
    uint256 private _fee;
    uint256 private decimal = 1e3;

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

        uint256 _amountIn = amountIn_ - ((amountIn_ * _fee) / decimal / 100);

        IUniswapV2Router(ROUTER).swapExactTokensForTokens(
            _amountIn,
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
        uint256 _amountIn = msg.value - ((msg.value * _fee) / decimal / 100);

        IUniswapV2Router(ROUTER).swapExactETHForTokens{value: _amountIn}(
            amountOutMin_,
            path_,
            to_,
            deadline_
        );
    }

    function swapTokenForEth(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] calldata path_,
        address to_,
        uint256 deadline_
    ) external {
        uint256 _amountIn = amountIn_ - ((amountIn_ * _fee) / decimal / 100);

        IUniswapV2Router(ROUTER).swapExactTokensForETH(
            _amountIn,
            amountOutMin_,
            path_,
            to_,
            deadline_
        );
    }

    function getAmountsOut(uint256 amountIn_, address[] calldata path_) public view returns (uint256[] memory amounts) {
        return IUniswapV2Router(ROUTER).getAmountsOut(amountIn_, path_);
    }

    function claimToken(address token_, address receipt_) public onlyOwner {
        IERC20(token_).safeTransfer(
            receipt_,
            IERC20(token_).balanceOf(address(this))
        );
    }

    function updateFee(uint256 fee_) public onlyOwner {
        _fee = fee_;
    }
}
