# Veil Project State

## Overview
Veil is a privacy-preserving conditional payment and rewards platform. It allows users to verify their eligibility for programs (like cashbacks, scholarships, and grants) and generate zero-knowledge proofs completely locally on their device, ensuring that sensitive data is never exposed.

## Implementation Status

Based on the current codebase, the following components have been implemented:

### 1. ZK ML Pipeline (`ml_zk`)
- **Status:** Implemented & Verified
- **Details:** A full EZKL pipeline is in place. It trains a logistic regression model for eligibility, exports it to ONNX format, and compiles it into a Halo2 Zero-Knowledge circuit. The pipeline generates a Solidity verifier (`Verifier.sol`) to verify the zkML proof on-chain. This handles complex logic, allowing users to prove they meet ML-based criteria (like spending habits) locally without revealing raw data.

### 2. Universal Rule Engine (`veil_circuits`)
- **Status:** Implemented
- **Details:** Basic Noir circuits have been written (e.g., `main.nr`) that evaluate simple rules. It takes public inputs (program rules like minimum balance and PRs) and private inputs (the user's local data) and cryptographically asserts that the user meets the requirements. 

### 3. Smart Contracts (`contracts`)
- **Status:** Implemented
- **Details:** A Foundry-based Ethereum smart contract environment is set up. The `VeilRegistry.sol` contract serves as the registry for programs and handles grant claims. It integrates with the generated `UltraVerifier` to verify the ZK proofs submitted by users before securely processing claims.

### 4. Client Application (`viel`)
- **Status:** Partially Complete (Phase 1)
- **Details:** The Flutter application is in development, establishing the front-end user journeys for program discovery, the conversational PrivatePilot AI, and integrating the ZK prover logic.

### 5. Shielded Payments (`js_railgun`)
- **Status:** Setup In Progress (Phase 5)
- **Details:** Initial dependencies have been installed for Railgun integration, which will be used to execute shielded, anonymous payouts on-chain once a ZK proof is verified.

---

## Hackathon Tracks Relevance (Answer to Image)

Based on the implemented architecture and goals of the Veil platform, the relevant tracks from the provided image are:

1. **Private Wallets and Payments:** 
   * **Reason:** The project's end goal is a "Prove → Verify → Pay" model, utilizing Railgun for shielded payments. The focus on preserving user privacy while claiming financial rewards and cashbacks fits perfectly into this track.
2. **Private AI on Ethereum:**
   * **Reason:** The project explicitly uses a local Machine Learning model (Logistic Regression -> ONNX) combined with EZKL to generate zkML proofs. These proofs verify the output of an AI inference locally and are then verified by a smart contract on Ethereum (`Verifier.sol`), completely fulfilling the premise of Private AI on Ethereum.
3. **Overall:**
   * **Reason:** As a general submission category for the hackathon.
