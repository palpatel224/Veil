// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Halo2Verifier.sol";
import "../src/NullifierRegistry.sol";
import "../src/PayoutController.sol";
import "../src/MockUSDC.sol";

/**
 * @title Deploy
 * @notice Foundry deployment script for Veil contracts on Sepolia testnet.
 *
 * Usage:
 *   export PRIVATE_KEY=<your_wallet_private_key>
 *   export SEPOLIA_RPC=https://sepolia.base.org   (Base Sepolia)
 *
 *   forge script script/Deploy.s.sol \
 *     --rpc-url $SEPOLIA_RPC \
 *     --private-key $PRIVATE_KEY \
 *     --broadcast \
 *     -vvvv
 *
 * After deployment, copy the printed addresses into:
 *   viel/lib/services/blockchain_service.dart
 */
contract Deploy is Script {

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        console.log("Deploying Veil contracts...");
        console.log("Deployer:", deployer);
        console.log("Balance: ", deployer.balance / 1e15, "mETH");

        vm.startBroadcast(deployerKey);

        // 1. Re-use Verifier
        Halo2Verifier verifier = Halo2Verifier(0x369005861e0E5E19229ED6D234C60750F159e241);
        console.log("Halo2Verifier re-used at:", address(verifier));

        // 2. Deploy new NullifierRegistry
        NullifierRegistry nullifierRegistry = new NullifierRegistry();
        console.log("NullifierRegistry deployed at:", address(nullifierRegistry));

        // 3. Deploy PayoutController pointing at both
        PayoutController controller = new PayoutController(
            address(verifier),
            address(nullifierRegistry)
        );
        console.log("PayoutController deployed at:", address(controller));

        // 4. Wire the registry to the controller
        nullifierRegistry.setController(address(controller));

        // Set real Railgun Sepolia Proxy
        controller.setRailgunSmartWallet(0xecfcf3b4ec647c4ca6d49108b311b7a7c9543fea);

        // Fund the 3 launch programs (0.001 ETH each = 0.003 ETH total)
        // controller.depositReward{value: 0.001 ether}(1, "Developer Starter Grant");
        // controller.depositReward{value: 0.001 ether}(2, "Open Source Champion");
        // controller.depositReward{value: 0.001 ether}(3, "GitHub Power User");

        // Fund blocsoc grants program
        controller.depositReward{value: 0.001 ether}(5, "blocsoc grants");

        // Deploy MockUSDC and fund program 4
        MockUSDC usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));

        // Mint 100 USDC to deployer
        usdc.mint(deployer, 100 * 10**6);

        // Approve PayoutController to spend 1 USDC
        usdc.approve(address(controller), 1 * 10**6);

        // Deposit 1 USDC reward
        controller.depositERC20Reward(4, "USDC Tester Grant", address(usdc), 1 * 10**6);

        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Copy these addresses into blockchain_service.dart:");
        console.log("VERIFIER_ADDRESS    =", address(verifier));
        console.log("NULLIFIER_ADDRESS   =", address(nullifierRegistry));
        console.log("CONTROLLER_ADDRESS  =", address(controller));

        vm.stopBroadcast();
    }
}
