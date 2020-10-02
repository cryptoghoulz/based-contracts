pragma solidity 0.5.17;

import "@openzeppelin/2.3.0/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/2.3.0/contracts/math/SafeMath.sol";

contract GonsConverter {
    using SafeMath for uint256;

    IERC20 public based;

    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint256 public constant INITIAL_FRAGMENTS_SUPPLY = 100000 * uint(10)**DECIMALS;
    uint256 public constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    constructor(address _based) public {
        based = IERC20(_based);
    }

    function gonsPerFragment() public view returns (uint256) {
        return TOTAL_GONS.div(based.totalSupply());
    }

    function fromGons(uint256 gonAmount) public view returns (uint256) {
        return gonAmount.div(gonsPerFragment());
    }

    function toGons(uint256 amount) public view returns (uint256) {
        return amount.mul(gonsPerFragment());
    }

    /// Suffers from rounding error
    function fromMbBased(uint256 mbAmount) public view returns (uint256 basedAmount) {
        basedAmount = fromGons(mbAmount.mul(1e18).div(INITIAL_FRAGMENTS_SUPPLY).mul(TOTAL_GONS.div(1e18)));
    }

    /// Suffers from rounding error
    function toMbBased(uint256 basedAmount) public view returns (uint256 mbAmount) {
        mbAmount = toGons(basedAmount).div(TOTAL_GONS.div(INITIAL_FRAGMENTS_SUPPLY));
    }
}
