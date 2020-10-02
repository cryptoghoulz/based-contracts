pragma solidity 0.4.24;


contract BlockRebaseOracle {
    function getData()
        external
        constant
        returns (uint256, bool)
    {
        return (10 ** 18, true);
    }
}
