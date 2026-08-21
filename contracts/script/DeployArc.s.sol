// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Halo2Verifier.sol";
import "../src/NullifierRegistry.sol";
import "../src/PayoutController.sol";

contract DeployArc is Script {

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        console.log("Deploying Veil contracts to ARC Testnet...");
        console.log("Deployer:", deployer);
        console.log("Balance: ", deployer.balance / 1e18, "ARC");

        vm.startBroadcast(deployerKey);

        // 1. Deploy new Halo2Verifier
        Halo2Verifier verifier = new Halo2Verifier();
        console.log("Halo2Verifier deployed at:", address(verifier));

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

        // Fund program 4 for ARC Testnet (1 ARC reward)
        controller.depositReward{value: 1 ether}(4, "ARC Testnet Native Grant");

        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("VERIFIER_ADDRESS    =", address(verifier));
        console.log("NULLIFIER_ADDRESS   =", address(nullifierRegistry));
        console.log("CONTROLLER_ADDRESS  =", address(controller));

        vm.stopBroadcast();
    }
}
