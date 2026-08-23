// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/IRailgunSmartWallet.sol";

interface IERC20Pull {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/// @notice Minimal stand-in for the real RailgunSmartWallet, for test purposes only.
///         Mirrors just enough of shield()'s external behavior (pull tokens via
///         transferFrom, record the note) to prove PayoutController bridges correctly.
contract MockRailgunSmartWallet is IRailgunSmartWallet {
    event MockShield(address indexed token, uint256 value, bytes32 npk);

    function shield(
        ShieldRequest[] calldata _shieldRequests
    ) external override {
        for (uint256 i = 0; i < _shieldRequests.length; i++) {
            CommitmentPreimage calldata preimage = _shieldRequests[i].preimage;
            require(
                IERC20Pull(preimage.token.tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    preimage.value
                ),
                "MockRailgunSmartWallet: transferFrom failed"
            );
            emit MockShield(
                preimage.token.tokenAddress,
                preimage.value,
                preimage.npk
            );
        }
    }
}
