pragma solidity 0.4.24;

interface YearnRewardsI {
    function starttime() external returns (uint256);
    function totalRewards() external returns (uint256);
    function y() external returns (address);
}

interface UniV2PairI {
    function sync() external;
}

interface ERC20MigratorI {
    function totalMigrated() external returns (uint256);
}
