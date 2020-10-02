pragma solidity 0.4.24;

import "openzeppelin-eth/contracts/math/SafeMath.sol";

import "./UFragmentsPolicy.sol";
import "./Interfaces.sol";
import "./openzeppelin-eth/ERC20Detailed.sol";
import "./openzeppelin-eth/Ownable.sol";

/**
 * @title Orchestrator
 * @notice The orchestrator is the main entry point for rebase operations. It coordinates the policy
 * actions with external consumers.
 */
contract Orchestrator is Ownable {
    using SafeMath for uint256;

    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }

    event TransactionFailed(address indexed destination, uint index, bytes data);

    // Stable ordering is not guaranteed.
    Transaction[] public transactions;

    UFragmentsPolicy public policy;
    YearnRewardsI public pool0;
    YearnRewardsI public pool1;
    ERC20Detailed public based;
    ERC20MigratorI public migrator;
    uint256 public rebaseRequiredSupply;
    address public deployer;
    UniV2PairI[3] public uniSyncs;

    uint256 constant SYNC_GAS = 50000;
    address constant uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    modifier onlyDeployer() {
        require(msg.sender == deployer);
        _;
    }

    // https://uniswap.org/docs/v2/smart-contract-integration/getting-pair-addresses/
    function genUniAddr(address left, address right) internal pure returns (UniV2PairI) {
        address first = left < right ? left : right;
        address second = left < right ? right : left;
        address pair = address(uint(keccak256(abi.encodePacked(
          hex'ff',
          uniFactory,
          keccak256(abi.encodePacked(first, second)),
          hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
        ))));
        return UniV2PairI(pair);
    }

    constructor () public {
        deployer = msg.sender;
    }
    /**
     * @param policy_ Address of the UFragments policy.
     * @param pool0_ Address of the YearnRewards pool0.
     * @param pool1_ Address of the YearnRewards pool1.
     * @param based_ Address of the Based token.
     */
    function initialize(
        address policy_,
        address pool0_,
        address pool1_,
        address based_,
        address weth_,
        address synth_sUSD_,
        uint256 rebaseRequiredSupply_,
        address migrator_
    ) public onlyDeployer initializer {
        // only deployer can initialize
        require(deployer == msg.sender);
        Ownable.initialize(msg.sender);

        policy = UFragmentsPolicy(policy_);
        pool0 = YearnRewardsI(pool0_);
        pool1 = YearnRewardsI(pool1_);
        based = ERC20Detailed(based_);
        migrator = ERC20MigratorI(migrator_);

        uniSyncs[0] = genUniAddr(based_, synth_sUSD_);   // BASED/sUSD (synth)
        uniSyncs[1] = genUniAddr(based_, pool0.y());   // BASED/curve sUSD
        uniSyncs[2] = genUniAddr(based_, weth_);       // BASED/WETH

        rebaseRequiredSupply = rebaseRequiredSupply_;
    }

    /**
     * @notice Main entry point to initiate a rebase operation.
     *         The Orchestrator calls rebase on the policy and notifies downstream applications.
     *         Contracts are guarded from calling, to avoid flash loan attacks on liquidity
     *         providers.
     *         If a transaction in the transaction list reverts, it is swallowed and the remaining
     *         transactions are executed.
     */
    function rebase()
        external
    {
        // wait for `rebaseRequiredSupply` token supply to be rewarded until rebase is possible
        // timeout after 4 weeks if people don't claim rewards so it's not stuck
        uint256 rewardsDistributed = migrator.totalMigrated().add(pool1.totalRewards());
        require(rewardsDistributed >= rebaseRequiredSupply || block.timestamp >= pool1.starttime() + 4 weeks);

        require(msg.sender == tx.origin);  // solhint-disable-line avoid-tx-origin

        policy.rebase();

        for (uint i = 0; i < uniSyncs.length; i++) {
            // Swiper no swiping.
            // using low level call to prevent reverts on remote error/non-existence
            address(uniSyncs[i]).call.gas(SYNC_GAS)(uniSyncs[i].sync.selector);
        }
    }
}
