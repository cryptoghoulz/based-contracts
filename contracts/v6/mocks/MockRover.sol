//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

import "@nomiclabs/buidler/console.sol";
import "../Rover.sol";

contract MockRover is Rover {
    constructor (
        address _based,
        address _rewardToken,
        string memory _pair
    )
        public
        Rover(_based, _rewardToken, _pair)
    {
    }
}
