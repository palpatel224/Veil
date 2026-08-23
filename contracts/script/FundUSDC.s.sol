// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PayoutController.sol";
import "../src/MockUSDC.sol";

contract FundUSDC is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerKey);

        PayoutController controller = PayoutController(payable(0x8d5a6F9D4aded9A30c79Bdd8A296DB6fB262b718));
        MockUSDC usdc = MockUSDC(0x06676a38D27f6BB712763245f457e4B9E181496C);

        // Approve PayoutController to spend 5 USDC
        usdc.approve(address(controller), 5 * 10**6);

        // Deposit 5 USDC reward
        controller.depositERC20Reward(4, "USDC Tester Grant", address(usdc), 5 * 10**6);

        vm.stopBroadcast();
    }
}
