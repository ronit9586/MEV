// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract MultiSwap {
    // address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  // (Mainnet) Address of Uniswap V2 Router
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // (Goerli) Address of Uniswap V2 Router
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
        uint256 lastBought = 0;
        IERC20(token).approve(address(uniswapV2Router), type(uint256).max);
        for (uint256 i = 0; i < numBuys; i++) {
            uint256 ethPerBuy = address(this).balance;
            console.log(ethPerBuy);
            uint[] memory amounts = uniswapV2Router.swapExactETHForTokens{
                value: ethPerBuy
            }(
                0,
                getPathForETHToToken(token),
                address(this),
                block.timestamp + 15 // Deadline
            );
            // Sell all tokens for ETH
            uint256 tokensBought = amounts[amounts.length - 1];
            console.log(tokensBought);
            if (i == numBuys - 1) {
                lastBought = tokensBought;
            } else {
                require(tokensBought > 0, "No tokens bought");
                uniswapV2Router.swapExactTokensForETH(
                    tokensBought,
                    1,
                    getPathForTokenToETH(token),
                    address(this),
                    block.timestamp + 15 // Deadline
                );
            }
        }

        require(lastBought >= tokenAmount, "Incorrect final token amount");
    }

    fallback() external payable {}

    function getPathForETHToToken(
        address token
    ) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = token;
        return path;
    }

    function getPathForTokenToETH(
        address token
    ) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapV2Router.WETH();
        return path;
    }
}
