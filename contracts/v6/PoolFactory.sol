//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

import {NoMintRewardPool} from "./RewardPool.sol";

contract PoolFactory {
    function createNewPool(
        address _rewardToken,
        address _rover,
        uint256 _duration,
        address _distributor
    ) external returns (address) {
        _distributor = (_distributor != address(0)) ? _distributor : msg.sender;

        NoMintRewardPool rewardsPool = new NoMintRewardPool(
            _rewardToken,
            _rover,
            _duration,
            _distributor  // who can notify of rewards
        );

        return address(rewardsPool);
    }
}
