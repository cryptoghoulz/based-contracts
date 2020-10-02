//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

interface IBasedGod {
    function getSellingSchedule() external view returns (uint256);
    function weth() external view returns (address);
    function susd() external view returns (address);
    function uniswapRouter() external view returns (address);
    function moonBase() external view returns (address);
}
