# Veil — Phase-Wise Build Roadmap

> Goal: Turn the current simulation into a real, end-to-end, cryptographically verified product testable on a real phone and a real blockchain.

---

## Phase 0 — Housekeeping
**Time Estimate: 1–2 hours**
**Goal: Make the app honest. Close the SQLite loop.**

These are quick fixes that should be done before anything else. They cost almost nothing but make every subsequent phase easier to debug.

### Tasks
- [ ] Fix `ProofService.fetchLocalSignatureData()` to read `github_signature` and `github_hash` from SQLite instead of returning hardcoded strings
- [ ] Fix `ProofService.generateProof()` to read `github_prs` and `total_balance` from SQLite instead of taking them as hardcoded parameters
- [ ] Remove unused imports flagged by `flutter analyze`
- [ ] Clean up the dead `reclaim_integration_service.dart` code (not wired to anything currently)

### Deliverable
The Data Sources → Generate Proof pipeline is honest. Data the user "collects" in the simulation actually feeds into the proof step.

---

## Phase 1 — Define the Programs
**Time Estimate: 2–3 hours (design work, minimal code)**
**Goal: Decide exactly what Veil will launch with. This unlocks everything downstream.**

This is a product decision, not an engineering one. The circuit, contracts, and UI all depend on knowing what programs exist and what they require.

### Tasks
- [ ] Define 3–5 launch programs with exact rules. Example:

| Program Name | Data Required | Threshold | Reward |
|---|---|---|---|
| Developer Starter Grant | GitHub PRs + Balance | PRs ≥ 3, Balance ≥ $1,000 | $100 USDC |
| Open Source Champion | GitHub PRs only | PRs ≥ 20 | NFT Badge |
| Entrepreneur Fund | Bank Balance only | Balance ≥ $25,000 | $500 USDC |

- [ ] Decide which data sources each program requires
- [ ] Confirm the circuit supports all required data types (update `main.nr` if new fields needed)
- [ ] Update `ProgramsScreen` to show real program cards with real rules and required data sources
- [ ] Add per-program status logic: checkmark if user has required data in SQLite, warning if they need to connect a source first

### Deliverable
A fully defined product. 3–5 real programs in the app. Users can see what they need to qualify and whether they currently qualify.

---

## Phase 2 — Real ZK Proof on the Phone
**Time Estimate: 2–3 days**
**Goal: Replace the fake 3-second delay with real cryptographic math running on the device.**

This is the hardest and most critical phase. Completing it unlocks Phase 3 automatically.

### How It Works
The Barretenberg ZK backend (which Noir uses) can be compiled to WebAssembly. Flutter can run WASM inside a headless WebView using `flutter_js`. Proof inputs come from SQLite, the math runs in WASM, and the output is a real proof byte array.

### Tasks
- [ ] Compile the Barretenberg backend to WASM using `bb.js` (the official JS version)
- [ ] Compile the Noir circuit (`main.nr`) against Barretenberg WASM to get a circuit artifact
- [ ] Add `flutter_js` or `webview_flutter` to the Flutter project
- [ ] Bundle the WASM binary and circuit artifact as Flutter assets
- [ ] Rewrite `ProofService.generateProof()` to invoke the WASM prover via a JS bridge with real SQLite inputs
- [ ] Test on a physical Android device — proof generation should take 2–10 seconds
- [ ] Display a real proof hex string in the Generate Proof screen

### Deliverable
Tapping "Generate Proof" runs real Barretenberg math on the user's phone. The output is a cryptographically valid proof byte array. The fake delay is gone.

---

## Phase 3 — Live Blockchain Verification
**Time Estimate: 1 day**
**Hard dependency: Phase 2 must be complete first.**
**Goal: Deploy contracts to testnet and let users submit real proofs on-chain.**

### Tasks

#### 3a — Generate the Verifier Contract
- [ ] Run `bb write_vk` on the compiled Noir circuit to generate the verification key
- [ ] Run `bb write_verifier` to auto-generate `UltraVerifier.sol`
- [ ] Copy `UltraVerifier.sol` into the `contracts/` directory

#### 3b — Set Up and Deploy
- [ ] Initialize Hardhat or Foundry in `contracts/`
- [ ] Get testnet ETH from the Base Sepolia faucet
- [ ] Deploy `UltraVerifier.sol` → record its address
- [ ] Deploy `VeilRegistry.sol` with the UltraVerifier address, attester's public key, and program thresholds
- [ ] Deploy one `VeilRegistry` per program

#### 3c — Flutter On-Chain Integration
- [ ] Add `web3dart` to the Flutter project
- [ ] Create a `BlockchainService` holding deployed contract addresses
- [ ] Wire the "Submit Proof" button to call `claimGrant()` with real proof bytes from Phase 2
- [ ] Show a real transaction hash as confirmation to the user

### Deliverable
A user applies to a program, the app generates a real ZK proof on-device, submits it to a live testnet contract, and gets back a real transaction hash. Full end-to-end pipeline is live.

---

## Phase 4 — Real Data Ingestion
**Time Estimate: 1–2 days**
**Goal: Replace the zkTLS simulation with real cryptographically signed data from the web.**

Left last because the simulation is good enough to test Phases 1–3, and the Reclaim external dependency is the highest-risk item.

### Tasks
- [ ] Evaluate the Reclaim Protocol JavaScript SDK (actively maintained, unlike the broken Flutter package)
- [ ] Use `flutter_js` (already added in Phase 2) to run the Reclaim JS SDK inside Flutter
- [ ] Create a JS bridge that calls the Reclaim JS SDK, triggers the secure WebView login flow, and returns the real proof back to Dart
- [ ] Parse the real Reclaim proof to extract verified data values and the real ECDSA signature
- [ ] Save the real signature and data to SQLite (replacing mocked values)
- [ ] Test the full pipeline: real GitHub login → SQLite → WASM Proof → testnet contract

### Deliverable
No simulations anywhere. A user logs into GitHub in a secure browser, the Reclaim node signs the data, a ZK proof is generated from real data, and it is verified on a live blockchain.

---

## Summary Timeline

```
Week 1
├── Phase 0: Housekeeping             (Day 1, half day)
└── Phase 1: Define Programs          (Day 1–2)

Week 1–2
└── Phase 2: Real WASM Prover         (Day 2–5, most complex)

Week 2
└── Phase 3: Blockchain Deployment    (Day 5–6)

Week 2–3
└── Phase 4: Real Data Ingestion      (Day 7–9)
```

---

## What "Done" Looks Like

A real user on a real Android phone can:
1. Open Veil and see 3–5 real grant programs
2. Tap "Connect GitHub" — a secure browser opens, they log in, data is intercepted and signed by a zkTLS node
3. See their profile update with verified GitHub stats
4. Tap "Apply" on a program they qualify for
5. Watch the phone run real ZK math for a few seconds
6. Get a transaction hash proving their eligibility was verified on-chain — without revealing a single private data point

That is the product.
