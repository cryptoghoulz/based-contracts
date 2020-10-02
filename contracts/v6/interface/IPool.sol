//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

interface IPool {
    function getReward() external;
    function stake(uint256 amount) external;
    function earned(address account) external view returns (uint256);
}
