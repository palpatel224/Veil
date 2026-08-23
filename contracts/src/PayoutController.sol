// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Halo2Verifier.sol";
import "./NullifierRegistry.sol";
import "./IRailgunSmartWallet.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @title PayoutController
 * @notice Core Veil contract. Accepts ZK proofs from the Flutter app, verifies them,
 *         prevents double-claiming via nullifiers, and pays out program rewards.
 *
 * @dev Flow:
 *   1. Sponsor deposits ETH or ERC20 into the contract per program via depositReward()
 *      / depositERC20Reward().
 *   2. User's phone generates proof + nullifier, and (for ERC20/shielded programs)
 *      pre-builds a RAILGUN ShieldRequest addressed to their own 0zk address using the
 *      RAILGUN engine/wallet SDK (see IRailgunSmartWallet.sol for the full rationale).
 *   3. User calls claimReward() — contract verifies proof, checks nullifier, pays out.
 *
 *   RAILGUN Integration (shielded ERC20 payouts):
 *   ERC20 rewards are no longer sent with a plain `transfer()`. Instead, _executePayout()
 *   forwards the reward into RAILGUN's shielded pool via `railgun.shield()`, using a
 *   ShieldRequest that the recipient pre-built off-chain for their own 0zk address. This
 *   severs the on-chain link between "this claim happened" and "this 0zk address received
 *   funds" — see IRailgunSmartWallet.sol for exactly what is and isn't possible on-chain.
 *   Native ETH programs are unaffected: RAILGUN only shields ERC20/721/1155 balances, so
 *   ETH rewards continue to use a plain call-transfer (wrapping to WETH first is possible
 *   but out of scope here).
 */
contract PayoutController {

    // ────────────────────────────────────────────────────
    //  State
    // ────────────────────────────────────────────────────

    Halo2Verifier public immutable verifier;
    NullifierRegistry public immutable nullifierRegistry;
    address public immutable owner;

    /// @notice The deployed RAILGUN privacy system entrypoint (RailgunSmartWallet.sol).
    ///         Unset (address(0)) until the owner wires it up via setRailgunSmartWallet().
    ///         Required for any program that pays out in ERC20 (see _executePayout()).
    IRailgunSmartWallet public railgun;

    /// @notice programId => deposited reward amount in wei
    mapping(uint256 => uint256) public programRewards;

    /// @notice programId => human-readable name (optional, for UI)
    mapping(uint256 => string) public programNames;

    /// @notice programId => token address (address(0) for ETH)
    mapping(uint256 => address) public programTokens;

    // ────────────────────────────────────────────────────
    //  Events
    // ────────────────────────────────────────────────────

    event RewardDeposited(uint256 indexed programId, uint256 amount, string name);
    event RailgunSmartWalletUpdated(address indexed railgun);
    /// @dev `recipient` is emitted as address(0) for shielded ERC20 claims — the real
    ///      destination is a private 0zk note and must never be linked on-chain to this event.
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
    error RailgunNotConfigured();
    error ShieldRequestMismatch();

    // ────────────────────────────────────────────────────
    //  Constructor
    // ────────────────────────────────────────────────────

    constructor(address _verifier, address _nullifierRegistry) {
        verifier = Halo2Verifier(_verifier);
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
        programTokens[programId] = address(0);
        emit RewardDeposited(programId, msg.value, name);
    }

    /**
     * @notice Sponsor deposits ERC20 token to fund a specific program's rewards.
     */
    function depositERC20Reward(uint256 programId, string calldata name, address token, uint256 amount) external onlyOwner {
        require(amount > 0, "PayoutController: zero deposit");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        programRewards[programId] += amount;
        programNames[programId] = name;
        programTokens[programId] = token;
        emit RewardDeposited(programId, amount, name);
    }

    /**
     * @notice Wires up the RAILGUN shielded-pool contract this controller shields into.
     *         Must be called once post-deployment before any ERC20 program can be claimed,
     *         mirroring how NullifierRegistry.setController() is wired in the deploy scripts.
     * @param _railgun Address of the network's deployed RailgunSmartWallet contract.
     */
    function setRailgunSmartWallet(address _railgun) external onlyOwner {
        railgun = IRailgunSmartWallet(_railgun);
        emit RailgunSmartWalletUpdated(_railgun);
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
     * @param recipient     Plain wallet address to receive the reward. Only used for
     *                      native-ETH programs (RAILGUN cannot shield native ETH). Pass
     *                      address(0) for ERC20 programs — the real destination comes
     *                      from `shieldRequest` instead.
     * @param shieldRequest A RAILGUN ShieldRequest pre-built OFF-CHAIN by the recipient's
     *                      own RAILGUN wallet/engine, addressed to their private 0zk
     *                      address (see IRailgunSmartWallet.sol). Required for ERC20
     *                      programs; ignored for native-ETH programs (pass a zero-valued
     *                      struct in that case).
     */
    function claimReward(
        uint256 programId,
        bytes calldata proof,
        uint256[] calldata publicInputs,
        bytes32 nullifierHash,
        address recipient,
        ShieldRequest calldata shieldRequest
    ) external {
        // 1. Ensure the program has funds available
        uint256 reward = programRewards[programId];
        if (reward == 0) revert NoRewardForProgram(programId);

        // 2. Ensure this nullifier hasn't been used (prevents double claiming)
        if (nullifierRegistry.isSpent(nullifierHash)) {
            revert AlreadyClaimed(nullifierHash);
        }

        // 3. Verify the ZK proof (structural + commitment check)
        bool valid = verifier.verifyProof(proof, publicInputs);
        if (!valid) revert InvalidProof();

        // 4. Mark nullifier as spent BEFORE transfer (reentrancy protection)
        nullifierRegistry.markSpent(nullifierHash);

        // 5. Clear the reward slot
        address token = programTokens[programId];
        programRewards[programId] = 0;

        // 6. Execute payout
        _executePayout(programId, recipient, reward, shieldRequest);

        // Native-ETH claims still log the real recipient; shielded ERC20 claims log
        // address(0) so this event can never be used to link the claim to a 0zk address.
        emit RewardClaimed(programId, nullifierHash, token == address(0) ? recipient : address(0), reward);
    }

    // ────────────────────────────────────────────────────
    //  Internal
    // ────────────────────────────────────────────────────

    /**
     * @dev Native ETH: plain call-transfer (RAILGUN only shields ERC20/721/1155, so this
     *      path is unaffected by the RAILGUN integration below).
     *
     *      ERC20: bridges the reward into RAILGUN's shielded pool instead of calling
     *      `IERC20.transfer(recipient, amount)` directly. See IRailgunSmartWallet.sol for
     *      the full interface contract and the reasoning behind using shield() rather
     *      than transact() here.
     */
    function _executePayout(
        uint256 programId,
        address recipient,
        uint256 amount,
        ShieldRequest calldata shieldRequest
    ) internal {
        address token = programTokens[programId];
        if (token == address(0)) {
            (bool success, ) = recipient.call{value: amount}("");
            if (!success) revert TransferFailed();
            return;
        }

        if (address(railgun) == address(0)) revert RailgunNotConfigured();

        // ── Validate the caller-supplied shield request before funding it ──────────
        // `shieldRequest` is opaque to us (npk/ciphertext are only meaningful to the
        // recipient's own wallet), but we CAN and MUST verify it is denominated in the
        // right token and the right amount — otherwise a malicious caller could claim
        // program funds into a shield note for the wrong asset/value while still
        // satisfying the proof + nullifier checks above.
        if (shieldRequest.preimage.token.tokenType != TokenType.ERC20) revert ShieldRequestMismatch();
        if (shieldRequest.preimage.token.tokenAddress != token) revert ShieldRequestMismatch();
        if (uint256(shieldRequest.preimage.value) != amount) revert ShieldRequestMismatch();

        // ── Bridge into the shielded pool ──────────────────────────────────────────
        // 1. RAILGUN's shield() pulls tokens via transferFrom(address(this), ...)
        //    internally (RailgunLogic.transferTokenIn), so it must be pre-approved.
        require(IERC20(token).approve(address(railgun), amount), "PayoutController: approve failed");

        // 2. Insert the recipient's pre-built note into RAILGUN's shielded pool. This
        //    is the only privacy-preserving primitive callable on-chain by a third
        //    party (see IRailgunSmartWallet.sol) — it deposits `amount` of `token` as a
        //    new private note, spendable only by whoever controls the 0zk address that
        //    the recipient encoded off-chain into `shieldRequest`. The on-chain trace
        //    left behind reveals only "PayoutController shielded `amount` of `token`",
        //    never which 0zk address received it.
        ShieldRequest[] memory batch = new ShieldRequest[](1);
        batch[0] = shieldRequest;
        railgun.shield(batch);
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
