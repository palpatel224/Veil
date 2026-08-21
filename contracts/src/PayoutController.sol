// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SimulatedVerifier.sol";
import "./NullifierRegistry.sol";

/**
 * @title PayoutController
 * @notice Core Veil contract. Accepts ZK proofs from the Flutter app, verifies them,
 *         prevents double-claiming via nullifiers, and sends ETH rewards to the recipient.
 *
 * @dev Flow:
 *   1. Sponsor deposits ETH into the contract per program via depositReward().
 *   2. User's phone generates proof + nullifier.
 *   3. User calls claimReward() — contract verifies proof, checks nullifier, pays out.
 *
 *   RAILGUN Integration Point:
 *   The _executePayout() function currently sends plain ETH. To integrate RAILGUN for
 *   shielded (private) payouts, replace the ETH transfer with a call to the RAILGUN
 *   RailgunSmartWallet.shield() function, targeting the user's 0zk address.
 */
contract PayoutController {

    // ────────────────────────────────────────────────────
    //  State
    // ────────────────────────────────────────────────────

    SimulatedVerifier public immutable verifier;
    NullifierRegistry public immutable nullifierRegistry;
    address public immutable owner;

    /// @notice programId => deposited reward amount in wei
    mapping(uint256 => uint256) public programRewards;

    /// @notice programId => human-readable name (optional, for UI)
    mapping(uint256 => string) public programNames;

    // ────────────────────────────────────────────────────
    //  Events
    // ────────────────────────────────────────────────────

    event RewardDeposited(uint256 indexed programId, uint256 amount, string name);
    event RewardClaimed(
        uint256 indexed programId,
        bytes32 indexed nullifierHash,
        address indexed recipient,
        uint256 amount
    );

    // ────────────────────────────────────────────────────
    //  Errors
    // ────────────────────────────────────────────────────

    error NotOwner();
    error InvalidProof();
    error AlreadyClaimed(bytes32 nullifierHash);
    error NoRewardForProgram(uint256 programId);
    error TransferFailed();

    // ────────────────────────────────────────────────────
    //  Constructor
    // ────────────────────────────────────────────────────

    constructor(address _verifier, address _nullifierRegistry) {
        verifier = SimulatedVerifier(_verifier);
        nullifierRegistry = NullifierRegistry(_nullifierRegistry);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ────────────────────────────────────────────────────
    //  Owner Actions
    // ────────────────────────────────────────────────────

    /**
     * @notice Sponsor deposits ETH to fund a specific program's rewards.
     * @param programId  Unique identifier for the program (e.g., 1 = Developer Grant).
     * @param name       Human-readable name for UI display.
     */
    function depositReward(uint256 programId, string calldata name) external payable onlyOwner {
        require(msg.value > 0, "PayoutController: zero deposit");
        programRewards[programId] += msg.value;
        programNames[programId] = name;
        emit RewardDeposited(programId, msg.value, name);
    }

    // ────────────────────────────────────────────────────
    //  User Actions
    // ────────────────────────────────────────────────────

    /**
     * @notice Submit a ZK proof to claim a program reward.
     *
     * @param programId     The program the user is claiming against.
     * @param proof         Raw proof bytes from ProofService.dart (512 bytes).
     * @param publicInputs  [SHA256(balance_threshold), SHA256(prs_threshold)] as uint256[].
     * @param nullifierHash SHA256(user_secret + program_id) — prevents double claiming.
     * @param recipient     The wallet address to receive the reward.
     */
    function claimReward(
        uint256 programId,
        bytes calldata proof,
        uint256[] calldata publicInputs,
        bytes32 nullifierHash,
        address recipient
    ) external {
        // 1. Ensure the program has funds available
        uint256 reward = programRewards[programId];
        if (reward == 0) revert NoRewardForProgram(programId);

        // 2. Ensure this nullifier hasn't been used (prevents double claiming)
        if (nullifierRegistry.isSpent(nullifierHash)) {
            revert AlreadyClaimed(nullifierHash);
        }

        // 3. Verify the ZK proof (structural + commitment check)
        bool valid = verifier.verify(proof, publicInputs);
        if (!valid) revert InvalidProof();

        // 4. Mark nullifier as spent BEFORE transfer (reentrancy protection)
        nullifierRegistry.markSpent(nullifierHash);

        // 5. Clear the reward slot
        programRewards[programId] = 0;

        // 6. Execute payout
        _executePayout(recipient, reward);

        emit RewardClaimed(programId, nullifierHash, recipient, reward);
    }

    // ────────────────────────────────────────────────────
    //  Internal
    // ────────────────────────────────────────────────────

    /**
     * @dev Sends ETH to recipient.
     *      RAILGUN Integration Point: replace this with a call to
     *      RailgunSmartWallet.shield(recipient_0zk_address, amount)
     *      to make the payout completely anonymous.
     */
    function _executePayout(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    // ────────────────────────────────────────────────────
    //  View Helpers (for Flutter UI)
    // ────────────────────────────────────────────────────

    /// @notice Returns reward amount and name for a given program.
    function getProgram(uint256 programId) external view returns (string memory name, uint256 rewardWei) {
        return (programNames[programId], programRewards[programId]);
    }

    /// @notice Allow contract to receive ETH for emergencies/re-funding.
    receive() external payable {}
}
