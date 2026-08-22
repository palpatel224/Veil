// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PayoutController.sol";
import "../src/MockUSDC.sol";

contract AddPrograms is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        vm.startBroadcast(deployerKey);

        PayoutController controller = PayoutController(payable(0xBb06731dfD073843c827794F6049cEA28E39A238));
        MockUSDC usdc = MockUSDC(0xfA3E6924BB0C5494075D35338F7e02Dc22897cb6);

        // Program 6: 0.001 ETH reward (fund it with 0.005 ETH so it can pay 5 people)
        controller.depositReward{value: 0.005 ether}(6, "ETH Hacker Grant", 0.001 ether);

        // Mint more USDC to deployer to fund Program 7
        usdc.mint(deployer, 10 * 10**6);
        usdc.approve(address(controller), 10 * 10**6);

        // Program 7: 2 USDC reward (fund it with 10 USDC so it can pay 5 people)
        controller.depositERC20Reward(7, "USDC Power User", address(usdc), 10 * 10**6, 2 * 10**6);

        vm.stopBroadcast();
    }
}
