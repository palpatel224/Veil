// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NullifierRegistry
 * @notice Tracks spent nullifiers to prevent the same proof from being used twice.
 *         A nullifier is SHA256(user_secret + program_id), computed on-device in Flutter.
 *         It uniquely identifies a claim attempt without revealing the user's identity.
 */
contract NullifierRegistry {

    /// @notice Mapping of nullifier hash => whether it has been spent.
    mapping(bytes32 => bool) public isSpent;

    /// @notice Address of the PayoutController that is allowed to mark nullifiers as spent.
    address public controller;
    address public owner;

    event NullifierSpent(bytes32 indexed nullifierHash);
    event ControllerSet(address indexed controller);

    error AlreadySpent(bytes32 nullifierHash);
    error Unauthorized();
    error AlreadyInitialized();

    modifier onlyController() {
        if (msg.sender != controller) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Sets the controller address. Can only be called once by the owner.
     *         This breaks the circular deployment dependency between NullifierRegistry
     *         and PayoutController.
     */
    function setController(address _controller) external {
        if (msg.sender != owner) revert Unauthorized();
        if (controller != address(0)) revert AlreadyInitialized();
        controller = _controller;
        emit ControllerSet(_controller);
    }

    /**
     * @notice Marks a nullifier as spent. Can only be called by the PayoutController.
     * @param nullifierHash The SHA256 hash of (user_secret + program_id).
     */
    function markSpent(bytes32 nullifierHash) external onlyController {
        if (isSpent[nullifierHash]) revert AlreadySpent(nullifierHash);
        isSpent[nullifierHash] = true;
        emit NullifierSpent(nullifierHash);
    }
}
