// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SimulatedVerifier.sol";
import "../src/NullifierRegistry.sol";
import "../src/PayoutController.sol";

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

        // 1. Deploy Verifier
        SimulatedVerifier verifier = new SimulatedVerifier();
        console.log("SimulatedVerifier deployed at:", address(verifier));

        // 2. Deploy NullifierRegistry (no controller yet)
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

        // Fund the 3 launch programs (0.01 ETH each = 0.03 ETH total)
        controller.depositReward{value: 0.01 ether}(1, "Developer Starter Grant");
        controller.depositReward{value: 0.01 ether}(2, "Open Source Champion");
        controller.depositReward{value: 0.01 ether}(3, "GitHub Power User");

        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Copy these addresses into blockchain_service.dart:");
        console.log("VERIFIER_ADDRESS    =", address(verifier));
        console.log("NULLIFIER_ADDRESS   =", address(nullifierRegistry));
        console.log("CONTROLLER_ADDRESS  =", address(controller));

        vm.stopBroadcast();
    }
}
