pragma solidity 0.4.24;

import "../UFragments.sol";


contract MockUFragments is UFragments {
    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint256 public constant INITIAL_FRAGMENTS_SUPPLY = 100000 * uint(10)**DECIMALS;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 public constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 public constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 public _totalSupply;
    uint256 public _gonsPerFragment;
    mapping(address => uint256) public _gonBalances;
}
