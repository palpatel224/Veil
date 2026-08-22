# Hackathon Submission Details

## The problem it solves

In today's digital economy, users are constantly required to expose their sensitive personal and financial data (like bank statements, income history, or transaction records) to third-party platforms just to prove they are eligible for programs such as cashback offers, grants, loans, or scholarships. This creates massive privacy risks and honeypots for data breaches.

**Veil** solves this by flipping the paradigm: instead of sending raw data to a server for evaluation, the evaluation rules are sent to the user's device. 

Veil allows users to use a conversational AI (PrivatePilot) to fetch their local authentic data and run a lightweight Machine Learning model *entirely on-device*. It then generates a Zero-Knowledge Proof (zkML via EZKL and Noir circuits) that cryptographically guarantees the user meets the eligibility criteria, without ever exposing their actual financial data. The proof is verified by a smart contract on Ethereum, triggering a shielded payment (via Railgun). 

It makes proving eligibility safer, completely private, and seamless—users get their rewards without sacrificing their identity or financial history.

## Challenges we ran into

Building a complete "Prove → Verify → Pay" pipeline that runs locally on-device while maintaining a premium UX was challenging:

1. **zkML Asynchronous Bindings in EZKL:**
   While building the ONNX to Halo2 zkML pipeline, we hit roadblocks with EZKL's Python API. Several crucial bindings (like `get_srs` for the KZG Structured Reference String and `create_evm_verifier` for generating the Solidity verifier) are backed by Rust/Tokio async functions. They couldn't be called synchronously and caused event loop crashes. We overcame this by wrapping the entire pipeline in an `asyncio` event loop, carefully orchestrating the transition from synchronous model training to asynchronous ZK proving.

2. **Bridging AI Inference with On-Chain Verification:**
   Quantizing our Logistic Regression model into fixed-point arithmetic for the ZK circuit introduced slight variations from the native PyTorch outputs. We had to carefully calibrate the circuit scale factors (`settings.json`) to ensure the on-chain `Verifier.sol` would accept the proof and that the threshold logic (e.g., matching the exact income/spending requirements) evaluated consistently.

3. **Mobile ZK Proving Overhead:**
   Generating ZK proofs locally on a mobile device (Flutter) requires significant computational overhead and can feel sluggish to the user. We solved the UX side of this by designing a "cypherpunk" cryptographic terminal animation that provides real-time haptic feedback and dynamic loading states, keeping the user engaged and informed while the heavy cryptographic operations happen in the background.

## Tracks Applied

*   **Private Wallets and Payments:** Veil utilizes shielded transaction infrastructure (like Railgun) to ensure that once a user's zero-knowledge eligibility proof is verified on-chain, their rewards and payouts are transferred completely anonymously.
*   **Private AI on Ethereum:** We built a local Machine Learning eligibility model, exported it to ONNX, and compiled it into a Halo2 zkML circuit using EZKL. The AI inference happens privately on the user's device, and the ZK proof of the AI's output is verified on-chain via our Solidity `VeilRegistry` contract.
*   **Overall:** As a general submission bridging Web3 privacy, AI, and consumer-friendly mobile UI.

## Technologies used

*   **Solidity:** For the `VeilRegistry` and on-chain ZK `Verifier` smart contracts.
*   **Flutter:** For the cross-platform mobile client, conversational AI interface (PrivatePilot), and local proof generation.
*   **EZKL / Halo2:** To convert our ONNX Machine Learning models into Zero-Knowledge circuits.
*   **Foundry:** For compiling, testing, and deploying the Ethereum smart contracts.
*   **Noir (Barretenberg):** For writing the universal rule engine circuits.
*   **Python (PyTorch / ONNX):** For training the financial eligibility logistic regression model.
*   **TypeScript (Railgun SDK):** For setting up the shielded payment flows.
