pragma solidity 0.4.24;

import "../UFragmentsPolicy.sol";

contract MockUFragmentsPolicy is UFragmentsPolicy {

    // must copy private values
    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_RATE = 10**6 * 10**DECIMALS;
    uint256 public constant MAX_SUPPLY = ~(uint256(1) << 255) / MAX_RATE;

    function rebaseWithStaticSupply(int256 _supplyDelta) external {
        // Apply the Dampening factor.
        int256 supplyDelta = _supplyDelta.div(rebaseLag.toInt256Safe());

        if (supplyDelta > 0 && uFrags.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
            supplyDelta = (MAX_SUPPLY.sub(uFrags.totalSupply())).toInt256Safe();
        }

        uint256 supplyAfterRebase = uFrags.rebase(uint(0), supplyDelta);
        assert(supplyAfterRebase <= MAX_SUPPLY);
    }

    function computeSupplyDeltaPublic(uint256 rate, uint256 targetRate)
        public
        view
        returns (int256)
    {
        return computeSupplyDelta(rate, targetRate);
    }

    function computeSupplyDelta(uint256 rate, uint256 targetRate)
        private
        view
        returns (int256)
    {
        if (withinDeviationThreshold(rate, targetRate)) {
            return 0;
        }

        // supplyDelta = totalSupply * (rate - targetRate) / targetRate
        int256 targetRateSigned = targetRate.toInt256Safe();
        return uFrags.totalSupply().toInt256Safe()
            .mul(rate.toInt256Safe().sub(targetRateSigned))
            .div(targetRateSigned);
    }

    function withinDeviationThreshold(uint256 rate, uint256 targetRate)
        private
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold)
            .div(10 ** DECIMALS);

        return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }
}
