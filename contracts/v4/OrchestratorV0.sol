pragma solidity 0.4.24;

import "openzeppelin-eth/contracts/math/SafeMath.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";

import "./UFragmentsPolicyV0.sol";

interface YearnRewardsI {
    function starttime() external returns (uint256);
    function totalRewards() external returns (uint256);
}

/**
 * @title Orchestrator
 * @notice The orchestrator is the main entry point for rebase operations. It coordinates the policy
 * actions with external consumers.
 */
contract OrchestratorV0 is Ownable {
    using SafeMath for uint256;

    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }

    event TransactionFailed(address indexed destination, uint index, bytes data);

    // Stable ordering is not guaranteed.
    Transaction[] public transactions;

    UFragmentsPolicyV0 public policy;
    YearnRewardsI public pool0;
    YearnRewardsI public pool1;
    ERC20Detailed public based;
    address public deployer;
    uint256 public rebaseRequiredSupply;

    constructor () public {
        deployer = msg.sender;
    }
    /**
     * @param policy_ Address of the UFragments policy.
     * @param pool0_ Address of the YearnRewards pool0.
     * @param pool1_ Address of the YearnRewards pool1.
     * @param based_ Address of the Based token.
     */
    function initialize(address policy_, address pool0_, address pool1_, address based_, uint256 rebaseRequiredSupply_) public initializer {
        // only deployer can initialize
        require(deployer == msg.sender);

        Ownable.initialize(msg.sender);
        policy = UFragmentsPolicyV0(policy_);
        pool0 = YearnRewardsI(pool0_);
        pool1 = YearnRewardsI(pool1_);
        based = ERC20Detailed(based_);
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
        uint256 rewardsDistributed = pool0.totalRewards().add(pool1.totalRewards());
        require(rewardsDistributed >= rebaseRequiredSupply || block.timestamp >= pool0.starttime() + 4 weeks);

        require(msg.sender == tx.origin);  // solhint-disable-line avoid-tx-origin

        policy.rebase();

        for (uint i = 0; i < transactions.length; i++) {
            Transaction storage t = transactions[i];
            if (t.enabled) {
                bool result =
                    externalCall(t.destination, t.data);
                if (!result) {
                    emit TransactionFailed(t.destination, i, t.data);
                    revert("Transaction Failed");
                }
            }
        }
    }

    /**
     * @notice Adds a transaction that gets called for a downstream receiver of rebases
     * @param destination Address of contract destination
     * @param data Transaction data payload
     */
    function addTransaction(address destination, bytes data)
        external
        onlyOwner
    {
        transactions.push(Transaction({
            enabled: true,
            destination: destination,
            data: data
        }));
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint index)
        external
        onlyOwner
    {
        require(index < transactions.length, "index out of bounds");

        if (index < transactions.length - 1) {
            transactions[index] = transactions[transactions.length - 1];
        }

        transactions.length--;
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint index, bool enabled)
        external
        onlyOwner
    {
        require(index < transactions.length, "index must be in range of stored tx list");
        transactions[index].enabled = enabled;
    }

    /**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */
    function transactionsSize()
        external
        view
        returns (uint256)
    {
        return transactions.length;
    }

    /**
     * @dev wrapper to call the encoded transactions on downstream consumers.
     * @param destination Address of destination contract.
     * @param data The encoded data payload.
     * @return True on success
     */
    function externalCall(address destination, bytes data)
        internal
        returns (bool)
    {
        bool result;
        assembly {  // solhint-disable-line no-inline-assembly
            // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let outputAddress := mload(0x40)

            // First 32 bytes are the padded length of data, so exclude that
            let dataAddress := add(data, 32)

            result := call(
                // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB)
                // + callValueTransferGas (9000) + callNewAccountGas
                // (25000, in case the destination address does not exist and needs creating)
                sub(gas, 34710),


                destination,
                0, // transfer value in wei
                dataAddress,
                mload(data),  // Size of the input, in bytes. Stored in position 0 of the array.
                outputAddress,
                0  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}
