//SPDX-License-Identifier: Beerware
pragma solidity >=0.6.0;

interface IScheduleProvider {
    function getSchedule() external view returns (uint256);
}
