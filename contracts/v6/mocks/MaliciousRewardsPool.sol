// SPDX-License-Identifier: Beerware

import {NoMintRewardPool} from "../RewardPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MaliciousRewardsPool is NoMintRewardPool {
    constructor(
        address _rewardToken,
        address _lpToken,
        uint256 _duration,
        address _rewardDistribution
    ) public NoMintRewardPool(_rewardToken, _lpToken, _duration, _rewardDistribution) {}

    function stealToken(address to) public {
        lpToken.transfer(to, rewardToken.balanceOf(address(this)));
    }
}
