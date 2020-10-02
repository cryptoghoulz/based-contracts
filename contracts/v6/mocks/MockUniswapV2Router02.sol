//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@nomiclabs/buidler/console.sol";

contract MockUniswapV2Router02 {
    address public WETH;
    uint public basedBought = 10**18;

    constructor (address _WETH) public {
        WETH = _WETH;
    }

    function getAmountsOut(uint amountIn, address[] memory path) public returns (uint[] memory) {
        uint[] memory amountsOut = new uint[](path.length);
        for (uint i = 0; i < path.length; i++) {
            amountsOut[i] = basedBought;
        }
        return amountsOut;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address receiver,
        uint timestamp
    ) public returns (uint[] memory) {
        console.log("IERC20(path[2]).balanceOf(address(this)) %s ", IERC20(path[2]).balanceOf(address(this)));
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[2]).transfer(receiver, basedBought);
        return getAmountsOut(amountIn, path);
    }
}
