// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSwap {
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  // Address of Uniswap V2 Router
    IUniswapV2Router02 public uniswapV2Router;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER);
    }

    function multiSwap(
        address token,
        uint256 tokenAmount,
        uint256 numBuys
    ) external payable {
        require(numBuys > 0 && msg.value > 0, "Invalid input values");

        uint256 initialTokenBalance = IERC20(token).balanceOf(msg.sender);
        uint256 ethPerBuy = msg.value / numBuys;

        for (uint256 i = 0; i < numBuys; i++) {
            // Buy token with ETH
            uniswapV2Router.swapExactETHForTokens{value: ethPerBuy}(
                0,
                getPathForETHToToken(token),
                msg.sender,
                block.timestamp + 15  // Deadline
            );

            // Sell all tokens for ETH
            uint256 tokenBalance = IERC20(token).balanceOf(msg.sender);
            require(tokenBalance > 0, "Insufficient token balance");
            uniswapV2Router.swapExactTokensForETH(
                tokenBalance,
                0,
                getPathForTokenToETH(token),
                msg.sender,
                block.timestamp + 15  // Deadline
            );
        }

        uint256 finalTokenBalance = IERC20(token).balanceOf(msg.sender);
        require(finalTokenBalance >= initialTokenBalance + tokenAmount, "Incorrect final token balance");
    }

    function getPathForETHToToken(address token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = token;
        return path;
    }

    function getPathForTokenToETH(address token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapV2Router.WETH();
        return path;
    }
}
