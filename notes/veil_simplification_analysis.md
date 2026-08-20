# Veil — Chokepoint Analysis & Simplification Decisions

> Objective: Identify every over-engineered or broken component, propose a simpler
> alternative, and define the leanest possible MVP that still demonstrates real
> cryptographic value.

---

## Chokepoint 1: ECDSA Signature Verification in the Noir Circuit

### What It Is
`main.nr` currently runs a full `ecdsa_secp256k1::verify_signature` call inside the ZK
proof. This is the most computationally expensive operation possible in a ZK circuit.

### Why It Was Added
To prove data provenance — that the user's balance/PR count was signed by a trusted
Reclaim node and not fabricated by the user.

### The Problem
ECDSA inside a Noir circuit generates roughly 100,000–500,000 constraints.

| Device | Estimated Proving Time |
|---|---|
| Desktop (M2 Mac) | 10–30 seconds |
| Mid-range Android | 3–10 minutes |
| Low-end Android | 10–20 minutes |

**10 minutes of phone CPU usage to apply for a grant is unusable.**

### Decision: Remove ECDSA from the circuit for MVP

The circuit becomes 2 lines of math. Proving time drops to **2–5 seconds** on mobile.
This is the single highest-impact change in the entire project.

**How is cheating prevented without the signature?**
- **Wallet balance** → The blockchain itself is the attester. The user signs the proof
  submission transaction with their wallet private key, proving wallet ownership.
  No additional signature needed.
- **GitHub PRs** → Self-reported in MVP. Accepted risk for a testnet demo. In V2, add
  a backend attestation server that countersigns GitHub API responses using
  **EdDSA/BabyJubjub**, which is ~100x cheaper in ZK than ECDSA secp256k1.

**The simplified circuit:**
```
assert(user_balance >= min_balance);
assert(user_prs >= min_prs);
```
That is all. Two assertions. Blazing fast. Still cryptographically valid.

---

## Chokepoint 2: Reclaim Protocol — Entirely Unnecessary for the MVP

### What It Was Being Used For
Fetching bank balance (abandoned) and GitHub PR count via TLS interception.

### The Problem
The official Flutter SDK (`reclaim_sdk v2.2.0`) calls a deprecated backend endpoint
(`/api/sdk/init-session/`) that no longer exists. The error is:

```
InitSessionError: This route is deprecated. Please use Update to the latest SDK.
```

No updated Flutter package has been published. The SDK is a dead end.

### Decision: Remove Reclaim Protocol entirely from the MVP

Both data sources can be obtained without Reclaim:

| Data | Old Approach | New Approach |
|---|---|---|
| Bank Balance | Reclaim zkTLS → bank HTTPS | **Replaced by wallet balance** |
| Wallet Balance | N/A | `web3dart` reads on-chain directly |
| GitHub PRs | Reclaim zkTLS → GitHub API | **Direct GitHub REST API call** |

Zero external dependencies. Zero broken SDKs. Zero user risk.

---

## Chokepoint 3: Bank Account — Replaced by Wallet Balance

### What It Is
The original "balance" data source was the user's bank account fetched via
Reclaim Protocol.

### The Problem
- Requires the user to log into their real bank in a third-party WebView
- Legally sensitive (financial data)
- Technically broken (Reclaim SDK is dead)
- Wrong product fit for a Web3 grant platform

### Decision: Use wallet balance permanently, not just as a workaround

**Why wallet is superior for Veil:**
1. No zkTLS needed — blockchain data is public, readable by anyone
2. WalletConnect is native and expected in Web3 apps
3. No legal/compliance risk
4. Data provenance is cryptographically guaranteed by the chain itself

**Privacy note:** The wallet address is public, but the ZK proof still hides the exact
balance. Verifiers only learn "balance ≥ threshold," not the actual amount. Users
who want stronger privacy should connect a separate wallet not linked to their identity.

---

## Chokepoint 4: One Smart Contract Per Program — Doesn't Scale

### What It Is
The current design requires deploying a separate `VeilRegistry.sol` for each grant
program, each with its own constructor parameters.

### The Problem
- 5 programs = 5 deployments, 5 contract addresses to manage
- If the Noir circuit changes even one line, the `UltraVerifier` must be regenerated
  and all contracts redeployed
- Flutter needs to hardcode all contract addresses

### Decision: One unified registry contract with a program mapping

A single `VeilRegistry` contract where an admin can register programs with their
`(minBalance, minPrs, rewardAmount)` configuration. Users call
`claimGrant(programId)`. One deployment. New programs added without any new contracts.

---

## Chokepoint 5: Attester Public Key as a Public Circuit Input — Fragile

### What It Is
The circuit takes the attester's ECDSA public key (X and Y coordinates, 64 bytes total)
as public inputs. The contract hardcodes these.

### The Problem
If a trusted attester rotates their signing key (which services do routinely), every
previously generated proof becomes unverifiable and every contract must be redeployed.
The system has no key rotation mechanism.

### Decision: This problem disappears when Chokepoint 1 is resolved

Removing ECDSA from the circuit removes the attester public key from both the circuit
inputs and the contract constructor. The problem is eliminated, not patched.

---

## Chokepoint 6: Missing `Program` Data Model in Flutter

### What It Is
There is currently no structured `Program` object anywhere in the Flutter codebase.
Thresholds, contract addresses, required data sources — none of it is modelled.

### The Problem
When a user taps "Apply" on a program card:
- The app doesn't know what minimum threshold to use for that program
- It doesn't know which contract address to submit the proof to
- It doesn't know which data sources to check before allowing the proof step

### Decision: Define a `Program` model before writing any more screen logic

Fields needed:
- `id`, `name`, `description`
- `minBalance`, `minPrs`
- `requiredDataSources` (list: wallet, github)
- `contractAddress` (testnet address after Phase 3)
- `reward` (description of what the user gets)

A static list of 3–5 programs is stored in the app. Every screen reads from this model.
This is not complex engineering — it is just a missing data structure.

---

## Chokepoint 7: flutter_js for WASM Proving — Unreliable

### What It Is
The plan was to use the `flutter_js` package to embed a lightweight JavaScript runtime
in Flutter, then run the Barretenberg WASM inside it.

### The Problem
`flutter_js` uses JavaScriptCore on iOS and a limited V8 build on Android. It does not
expose full WASM APIs. Large, complex WASM binaries like Barretenberg may fail silently
or crash on specific device configurations.

### Decision: Use `webview_flutter` with an embedded HTML page instead

Full browser engines (Chromium on Android, WebKit on iOS) have battle-tested, native
WASM support. The approach:
1. Bundle the Barretenberg WASM and circuit artifact as Flutter assets
2. Serve them via a local embedded HTML file inside a hidden WebView
3. Flutter communicates with the WebView via JavaScript channels
4. The proof runs in the WebView, the result is passed back to Flutter as a string

This is how most production mobile ZK apps work in the real world.

---

## Summary: Cut, Keep, Change

| Component | Current State | Decision |
|---|---|---|
| ECDSA in Noir circuit | In circuit, 3–10 min on mobile | **REMOVE for MVP. EdDSA in V2.** |
| Reclaim Protocol SDK | Deprecated, broken | **REMOVE entirely.** |
| Bank account | Scrapped, risky | **REPLACE permanently with wallet.** |
| One contract per program | Doesn't scale | **ONE contract, program registry.** |
| Attester key in contract | Fragile, rotation-breaking | **REMOVE (follows from ECDSA removal).** |
| Program data model | Missing entirely | **ADD before writing more screens.** |
| flutter_js for WASM | Unreliable WASM support | **REPLACE with webview_flutter.** |
| SQLite Secure Enclave | Complete and correct | **KEEP as-is.** |
| Flutter UI/UX | Complete, polished | **KEEP as-is.** |
| Noir circuit structure | Good, just needs simplification | **SIMPLIFY to 2-assertion version.** |

---

## What the Simplified MVP Actually Is

After all simplifications, the product is:

```
User connects wallet
  └── web3dart reads on-chain balance → saved to SQLite

User connects GitHub
  └── GitHub REST API call → PR count saved to SQLite

User taps "Apply" on a program
  └── App checks SQLite for required data
  └── App runs 2-line Noir circuit in WebView WASM → proof in ~3 seconds
  └── App submits proof to single VeilRegistry contract
  └── Contract verifies math → records claim → emits event

User gets confirmation with transaction hash
```

**No Reclaim Protocol. No ECDSA. No bank account. No multiple contracts.**

Everything that was removed was theoretical security for an adversarial production
environment. Add it back layer by layer once the product is live.

---

## Revised Build Timeline After Simplifications

| Phase | Work | Estimate |
|---|---|---|
| 0 | Housekeeping fixes | Half day |
| 1 | Define Program model + update Programs screen | 1 day |
| 2 | Simplify Noir circuit + compile to WASM + WebView integration | 1–2 days |
| 3 | Deploy simplified contracts to Base Sepolia | Half day |
| 4 | Wire real GitHub API call + WalletConnect | 1 day |

**Total: ~5 days to a fully working, on-chain testable product.**

This is roughly half the time of the original roadmap, and the result is
more reliable because every external dependency has been eliminated or replaced.
