//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

interface IPoolFactory {
    function createNewPool(
        address _rewardToken,
        address _rover,
        uint256 _duration,
        address _distributor
    ) external returns (address);
}
