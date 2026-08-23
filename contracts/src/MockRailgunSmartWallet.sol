// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IRailgunSmartWallet.sol";

interface IMockERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MockRailgunSmartWallet is IRailgunSmartWallet {
    event Shielded(address token, uint256 amount);

    function shield(ShieldRequest[] calldata _shieldRequests) external override {
        for (uint i = 0; i < _shieldRequests.length; i++) {
            ShieldRequest calldata req = _shieldRequests[i];
            
            if (req.preimage.token.tokenType == TokenType.ERC20) {
                address token = req.preimage.token.tokenAddress;
                uint256 amount = req.preimage.value;
                require(IMockERC20(token).transferFrom(msg.sender, address(this), amount), "MockRailgun: transferFrom failed");
                emit Shielded(token, amount);
            }
        }
    }
}
