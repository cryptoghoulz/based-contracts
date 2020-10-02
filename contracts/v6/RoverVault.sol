//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

import "./Rover.sol";

contract RoverVault is Rover {
    constructor(address _based, address _rewardToken, string memory _pair)
        public
        Rover(_based, _rewardToken, _pair)
    {}

    function startRover() public onlyOwner {
        init();
    }
}
