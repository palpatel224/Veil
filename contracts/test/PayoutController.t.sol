// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimulatedVerifier.sol";
import "../src/NullifierRegistry.sol";
import "../src/PayoutController.sol";

/**
 * @title PayoutControllerTest
 * @notice Foundry tests for the Veil PayoutController.
 *         Run with: forge test -vv
 */
contract PayoutControllerTest is Test {

    SimulatedVerifier verifier;
    NullifierRegistry nullifierRegistry;
    PayoutController controller;

    address owner   = address(0xABCD);
    address user    = address(0x1234);

    uint256 constant PROGRAM_ID = 1;
    uint256 constant REWARD_ETH = 0.01 ether;

    // ── Build a valid-looking 512-byte proof ──────────────────────────────────
    // Mirrors what ProofService.dart generates:
    //   - First 32 bytes: non-zero commitment (simulated HMAC-SHA256)
    //   - Remaining 480 bytes: pseudorandom expansion
    bytes validProof;

    // Public inputs: SHA256("balance_threshold:100") and SHA256("prs_threshold:1")
    uint256[] validPublicInputs;

    // Nullifier: SHA256(user_secret + program_id)
    bytes32 nullifierHash;

    function setUp() public {
        vm.startPrank(owner);

        // Step 1: Deploy verifier
        verifier = new SimulatedVerifier();

        // Step 2: Deploy registry (no controller yet)
        nullifierRegistry = new NullifierRegistry();

        // Step 3: Deploy controller pointing at registry
        controller = new PayoutController(address(verifier), address(nullifierRegistry));

        // Step 4: Wire registry to the controller (one-time call)
        nullifierRegistry.setController(address(controller));

        // Fund program 1 with test ETH
        vm.deal(owner, 1 ether);
        controller.depositReward{value: REWARD_ETH}(PROGRAM_ID, "Developer Starter Grant");

        vm.stopPrank();

        // Build a valid 512-byte proof matching ProofService.dart output
        validProof = new bytes(512);
        for (uint i = 0; i < 32; i++) {
            validProof[i] = bytes1(uint8(0xab)); // non-zero commitment
        }
        for (uint i = 32; i < 512; i++) {
            validProof[i] = bytes1(uint8(i % 256));
        }

        // Public inputs: non-zero hashes representing thresholds
        validPublicInputs = new uint256[](2);
        validPublicInputs[0] = uint256(keccak256("balance_threshold:100"));
        validPublicInputs[1] = uint256(keccak256("prs_threshold:1"));

        // Nullifier: simulates SHA256(user_secret + program_id) from Flutter
        nullifierHash = keccak256(abi.encodePacked("user_secret_123", PROGRAM_ID));
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Happy Path
    // ─────────────────────────────────────────────────────────────────────────

    function test_HappyPath_ClaimSucceeds() public {
        uint256 balanceBefore = user.balance;

        vm.prank(user);
        controller.claimReward(
            PROGRAM_ID,
            validProof,
            validPublicInputs,
            nullifierHash,
            user
        );

        // User received the ETH
        assertEq(user.balance, balanceBefore + REWARD_ETH, "User did not receive reward");

        // Program reward slot is now zero
        (, uint256 remaining) = controller.getProgram(PROGRAM_ID);
        assertEq(remaining, 0, "Reward slot not zeroed after claim");
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Double-Claim Rejection
    // ─────────────────────────────────────────────────────────────────────────

    function test_DoubleClaim_Reverts() public {
        // First claim succeeds
        vm.prank(user);
        controller.claimReward(
            PROGRAM_ID, validProof, validPublicInputs, nullifierHash, user
        );

        // Refund the program so funds aren't the issue
        vm.prank(owner);
        controller.depositReward{value: REWARD_ETH}(PROGRAM_ID, "Developer Starter Grant");

        // Second claim with same nullifier must revert
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(PayoutController.AlreadyClaimed.selector, nullifierHash));
        controller.claimReward(
            PROGRAM_ID, validProof, validPublicInputs, nullifierHash, user
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Invalid Proof Rejection
    // ─────────────────────────────────────────────────────────────────────────

    function test_InvalidProof_ZeroCommitment_Reverts() public {
        // Proof where first 32 bytes are all zero (invalid commitment)
        bytes memory badProof = new bytes(512);

        vm.prank(user);
        vm.expectRevert("SimulatedVerifier: zero commitment");
        controller.claimReward(
            PROGRAM_ID, badProof, validPublicInputs, nullifierHash, user
        );
    }

    function test_InvalidProof_TooShort_Reverts() public {
        bytes memory shortProof = new bytes(10);

        vm.prank(user);
        vm.expectRevert("SimulatedVerifier: proof too short");
        controller.claimReward(
            PROGRAM_ID, shortProof, validPublicInputs, nullifierHash, user
        );
    }

    function test_InvalidProof_WrongPublicInputCount_Reverts() public {
        uint256[] memory badInputs = new uint256[](1);
        badInputs[0] = validPublicInputs[0];

        vm.prank(user);
        vm.expectRevert("SimulatedVerifier: need 2 public inputs");
        controller.claimReward(
            PROGRAM_ID, validProof, badInputs, nullifierHash, user
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  No Reward for Program
    // ─────────────────────────────────────────────────────────────────────────

    function test_UnfundedProgram_Reverts() public {
        uint256 unknownProgram = 999;

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(PayoutController.NoRewardForProgram.selector, unknownProgram));
        controller.claimReward(
            unknownProgram, validProof, validPublicInputs, nullifierHash, user
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Program Info
    // ─────────────────────────────────────────────────────────────────────────

    function test_GetProgram_ReturnsCorrectInfo() public {
        (string memory name, uint256 reward) = controller.getProgram(PROGRAM_ID);
        assertEq(name, "Developer Starter Grant");
        assertEq(reward, REWARD_ETH);
    }
}
