// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimulatedVerifier.sol";
import "../src/NullifierRegistry.sol";
import "../src/PayoutController.sol";
import "../src/MockUSDC.sol";
import "../src/IRailgunSmartWallet.sol";
import "./mocks/MockRailgunSmartWallet.sol";

/**
 * @title PayoutControllerRailgunTest
 * @notice Verifies the shielded ERC20 payout path added to PayoutController:
 *         claimReward() must bridge into RAILGUN's shield() instead of a plain
 *         IERC20.transfer(), using a caller-supplied ShieldRequest.
 * Run with: forge test --match-path test/PayoutControllerRailgun.t.sol -vv
 */
contract PayoutControllerRailgunTest is Test {
    SimulatedVerifier verifier;
    NullifierRegistry nullifierRegistry;
    PayoutController controller;
    MockUSDC usdc;
    MockRailgunSmartWallet railgun;

    address owner = address(0xABCD);
    address user = address(0x1234);

    uint256 constant PROGRAM_ID = 4;
    uint256 constant REWARD_USDC = 1_000_000; // 1 USDC (6 decimals)

    bytes validProof;
    uint256[] validPublicInputs;
    bytes32 nullifierHash;

    function setUp() public {
        vm.startPrank(owner);

        verifier = new SimulatedVerifier();
        nullifierRegistry = new NullifierRegistry();
        controller = new PayoutController(
            address(verifier),
            address(nullifierRegistry)
        );
        nullifierRegistry.setController(address(controller));

        railgun = new MockRailgunSmartWallet();
        controller.setRailgunSmartWallet(address(railgun));

        usdc = new MockUSDC();
        usdc.mint(owner, REWARD_USDC);
        usdc.approve(address(controller), REWARD_USDC);
        controller.depositERC20Reward(
            PROGRAM_ID,
            "USDC Tester Grant",
            address(usdc),
            REWARD_USDC
        );

        vm.stopPrank();

        validProof = new bytes(512);
        for (uint i = 0; i < 32; i++) {
            validProof[i] = bytes1(uint8(0xab));
        }
        for (uint i = 32; i < 512; i++) {
            validProof[i] = bytes1(uint8(i % 256));
        }

        validPublicInputs = new uint256[](2);
        validPublicInputs[0] = uint256(keccak256("balance_threshold:100"));
        validPublicInputs[1] = uint256(keccak256("prs_threshold:1"));

        nullifierHash = keccak256(
            abi.encodePacked("user_secret_123", PROGRAM_ID)
        );
    }

    /// @dev Builds a ShieldRequest as the recipient's off-chain RAILGUN wallet would.
    function _shieldRequestFor(
        address token,
        uint256 amount,
        bytes32 npk
    ) internal pure returns (ShieldRequest memory) {
        return
            ShieldRequest({
                preimage: CommitmentPreimage({
                    npk: npk,
                    token: TokenData({
                        tokenType: TokenType.ERC20,
                        tokenAddress: token,
                        tokenSubID: 0
                    }),
                    value: uint120(amount)
                }),
                ciphertext: ShieldCiphertext({
                    encryptedBundle: [
                        bytes32(uint256(1)),
                        bytes32(uint256(2)),
                        bytes32(uint256(3))
                    ],
                    shieldKey: bytes32(uint256(4))
                })
            });
    }

    function test_ShieldedClaim_ForwardsToRailgunPool() public {
        ShieldRequest memory req = _shieldRequestFor(
            address(usdc),
            REWARD_USDC,
            bytes32(uint256(0xbeef))
        );

        vm.expectEmit(true, false, false, true, address(railgun));
        emit MockRailgunSmartWallet.MockShield(
            address(usdc),
            REWARD_USDC,
            bytes32(uint256(0xbeef))
        );

        vm.prank(user);
        controller.claimReward(
            PROGRAM_ID,
            validProof,
            validPublicInputs,
            nullifierHash,
            address(0),
            req
        );

        // Funds actually moved out of PayoutController into the (mock) shielded pool.
        assertEq(
            usdc.balanceOf(address(controller)),
            0,
            "controller should be drained"
        );
        assertEq(
            usdc.balanceOf(address(railgun)),
            REWARD_USDC,
            "shielded pool should hold the note's funds"
        );
        // The plain recipient address is never paid directly for a shielded program.
        assertEq(
            usdc.balanceOf(user),
            0,
            "recipient must not receive a public transfer"
        );

        (, uint256 remaining) = controller.getProgram(PROGRAM_ID);
        assertEq(remaining, 0, "reward slot not cleared");
    }

    function test_ShieldedClaim_EmitsRecipientZeroInEvent() public {
        ShieldRequest memory req = _shieldRequestFor(
            address(usdc),
            REWARD_USDC,
            bytes32(uint256(0xbeef))
        );

        vm.expectEmit(true, true, true, true, address(controller));
        emit PayoutController.RewardClaimed(
            PROGRAM_ID,
            nullifierHash,
            address(0),
            REWARD_USDC
        );

        vm.prank(user);
        controller.claimReward(
            PROGRAM_ID,
            validProof,
            validPublicInputs,
            nullifierHash,
            address(0),
            req
        );
    }

    function test_ShieldedClaim_WrongTokenAddress_Reverts() public {
        MockUSDC otherToken = new MockUSDC();
        ShieldRequest memory req = _shieldRequestFor(
            address(otherToken),
            REWARD_USDC,
            bytes32(uint256(1))
        );

        vm.prank(user);
        vm.expectRevert(PayoutController.ShieldRequestMismatch.selector);
        controller.claimReward(
            PROGRAM_ID,
            validProof,
            validPublicInputs,
            nullifierHash,
            address(0),
            req
        );
    }

    function test_ShieldedClaim_WrongValue_Reverts() public {
        ShieldRequest memory req = _shieldRequestFor(
            address(usdc),
            REWARD_USDC - 1,
            bytes32(uint256(1))
        );

        vm.prank(user);
        vm.expectRevert(PayoutController.ShieldRequestMismatch.selector);
        controller.claimReward(
            PROGRAM_ID,
            validProof,
            validPublicInputs,
            nullifierHash,
            address(0),
            req
        );
    }

    function test_ShieldedClaim_WrongTokenType_Reverts() public {
        ShieldRequest memory req = _shieldRequestFor(
            address(usdc),
            REWARD_USDC,
            bytes32(uint256(1))
        );
        req.preimage.token.tokenType = TokenType.ERC721;

        vm.prank(user);
        vm.expectRevert(PayoutController.ShieldRequestMismatch.selector);
        controller.claimReward(
            PROGRAM_ID,
            validProof,
            validPublicInputs,
            nullifierHash,
            address(0),
            req
        );
    }

    function test_ShieldedClaim_RailgunNotConfigured_Reverts() public {
        // Fresh controller + its own registry (a controller must be the one and only
        // address a NullifierRegistry is wired to) with railgun left unset.
        vm.startPrank(owner);
        NullifierRegistry freshRegistry = new NullifierRegistry();
        PayoutController freshController = new PayoutController(
            address(verifier),
            address(freshRegistry)
        );
        freshRegistry.setController(address(freshController));
        usdc.mint(owner, REWARD_USDC);
        usdc.approve(address(freshController), REWARD_USDC);
        freshController.depositERC20Reward(
            PROGRAM_ID,
            "Unwired",
            address(usdc),
            REWARD_USDC
        );
        vm.stopPrank();

        ShieldRequest memory req = _shieldRequestFor(
            address(usdc),
            REWARD_USDC,
            bytes32(uint256(1))
        );

        vm.prank(user);
        vm.expectRevert(PayoutController.RailgunNotConfigured.selector);
        freshController.claimReward(
            PROGRAM_ID,
            validProof,
            validPublicInputs,
            nullifierHash,
            address(0),
            req
        );
    }
}
