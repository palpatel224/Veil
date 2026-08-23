// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IRailgunSmartWallet — bridge interface to the deployed RAILGUN privacy system
 *
 * @dev WHY THIS FILE EXISTS
 *   RAILGUN's on-chain contract (`RailgunSmartWallet.sol`, see
 *   https://github.com/Railgun-Privacy/contract/blob/main/contracts/logic/RailgunSmartWallet.sol)
 *   exposes exactly two entrypoints that move value in/out of the shielded pool:
 *
 *     1. `shield(ShieldRequest[])`   — PUBLIC balance  -> PRIVATE (shielded) note.
 *        Does NOT require a zk-SNARK proof. Any address (including another
 *        smart contract, like PayoutController) can call this directly on-chain.
 *
 *     2. `transact(Transaction[])`  — PRIVATE note     -> PRIVATE note / unshield.
 *        REQUIRES a zk-SNARK proof generated off-chain by the party that owns the
 *        spending key for the input note(s). Only the RAILGUN engine/wallet SDK
 *        (e.g. `@railgun-community/wallet`, `@kohaku-eth/railgun`) running on the
 *        SENDER's device can produce that proof — a Solidity contract holding a
 *        PUBLIC token balance (like PayoutController) has no shielded balance and
 *        no spending key, so it can NEVER call `transact()` on someone else's
 *        behalf. This is a cryptographic limitation, not a missing feature.
 *
 *   Because of that split, the only RAILGUN primitive a payout contract can use to
 *   turn a public token reward into something that "arrives" at a shielded 0zk
 *   address is `shield()`. That is what PayoutController calls below. The struct
 *   layout here is copied field-for-field (same types, same order) from RAILGUN's
 *   `Globals.sol` so that ABI encoding matches the real deployed contract exactly:
 *   https://github.com/Railgun-Privacy/contract/blob/main/contracts/logic/Globals.sol
 *
 * @dev HOW A "SHIELDED RECIPIENT (0zk) ADDRESS" ACTUALLY GETS ENCODED
 *   A 0zk address is a bech32-encoded bundle of two BabyJubJub curve points
 *   (a spending public key and a viewing public key) — it is NOT an EVM `address`
 *   and cannot be passed as one. To shield tokens *for* a specific 0zk address,
 *   the depositor doesn't hand the contract a 0zk string at all. Instead:
 *     - The RECIPIENT's own RAILGUN wallet/engine (off-chain) derives a note
 *       public key (`npk`) and encrypted `ShieldCiphertext` bound to their 0zk
 *       address, for a specific token + amount.
 *     - That pre-built `ShieldRequest` (public inputs only — no secrets, no
 *       proof needed for shield) is handed to whoever is depositing.
 *     - PayoutController just forwards the ERC-20 balance and relays that
 *       pre-built request into `railgun.shield()`.
 *   This mirrors the reference implementation's `shield()` helper
 *   ("Public ERC-20 -> shielded pool", https://github.com/vg239/kohaku-railgun).
 *
 * @dev COMMON MISTAKES THIS INTERFACE AVOIDS (see kohaku-railgun README "Troubleshooting"
 *      and https://road-to-devcon.vercel.app/?session=3 for the live-demo walkthrough):
 *     - Do NOT try to call `transact()` from a contract expecting a "private transfer"
 *       — there is no proof to supply, so it will always revert.
 *     - Do NOT pass a raw `address` for the 0zk recipient — it must be encoded
 *       off-chain into `CommitmentPreimage.npk` + `ShieldCiphertext` by the
 *       recipient's own wallet.
 *     - Always `approve()` the RAILGUN contract for the exact amount before
 *       calling `shield()` — RAILGUN pulls tokens via `transferFrom(msg.sender, ...)`
 *       internally, so an unset/insufficient allowance reverts with
 *       "transfer amount exceeds allowance".
 */

/// @notice Token category shielded by RAILGUN. Veil only ever uses ERC20.
enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}

/// @notice Identifies the asset being shielded — mirrors Globals.sol::TokenData.
struct TokenData {
    TokenType tokenType;
    address tokenAddress;
    uint256 tokenSubID; // unused for ERC20, must be 0
}

/**
 * @notice The plaintext "note" being created inside the shielded pool.
 * @dev `npk` (note public key) is `Poseidon(Poseidon(spendingPublicKey, nullifyingKey), random)` —
 *      computed OFF-CHAIN by the recipient's RAILGUN wallet from their 0zk address.
 *      PayoutController treats it as an opaque bytes32; it cannot derive or
 *      validate it on-chain (that would require the recipient's private key material).
 */
struct CommitmentPreimage {
    bytes32 npk;
    TokenData token;
    uint120 value; // amount being shielded, MUST equal the reward amount
}

/**
 * @notice Encrypted metadata that lets the recipient's wallet detect + decrypt the
 *         note during a balance scan, without revealing anything on-chain.
 * @dev Opaque to PayoutController — generated off-chain, forwarded as-is.
 */
struct ShieldCiphertext {
    bytes32[3] encryptedBundle;
    bytes32 shieldKey;
}

/// @notice One shield deposit = one preimage + its ciphertext. Mirrors Globals.sol::ShieldRequest.
struct ShieldRequest {
    CommitmentPreimage preimage;
    ShieldCiphertext ciphertext;
}

/**
 * @notice Minimal external interface onto the deployed RailgunSmartWallet contract.
 *         Only `shield()` is declared — PayoutController must never call `transact()`
 *         (see file-level @dev notes above for why that's cryptographically impossible
 *         from a contract acting on someone else's behalf).
 */
interface IRailgunSmartWallet {
    /**
     * @notice Deposits `_shieldRequests` worth of public ERC20 balance (pulled from
     *         `msg.sender` via `transferFrom`) into the shielded pool as new private
     *         notes, addressed to whichever 0zk address each `preimage.npk` encodes.
     * @param _shieldRequests Batch of pre-built shield requests (see ShieldRequest above).
     */
    function shield(ShieldRequest[] calldata _shieldRequests) external;
}
