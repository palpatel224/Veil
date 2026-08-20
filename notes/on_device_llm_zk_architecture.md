# Veil Hybrid Architecture: On-Device LLM + zkML

This document outlines the architectural feasibility and design of running an on-device Large Language Model (LLM) for the `PrivatePilot` chat interface alongside Zero-Knowledge Machine Learning (zkML) for generating cryptographic proofs of eligibility.

## The Problem
Veil requires two distinct computational capabilities:
1. **Conversational Interface (`PrivatePilot`)**: Needs a Generative LLM to understand natural language questions about local financial data (e.g., "Do I qualify?", "What was my highest expense?").
2. **Cryptographic Proof Generation (Claim Engine)**: Needs a verifiable model that runs through `EZKL` to generate a Zero-Knowledge proof of eligibility for the Ethereum smart contracts.

Generating a ZK proof for an entire LLM inference is currently computationally infeasible on mobile devices (it would require massive RAM and take hours or days). 

## The Solution: Hybrid Decoupled Architecture

We decouple the *conversational intelligence* from the *cryptographic proof generation*.

### 1. The Conversational Layer (MediaPipe + Local LLM)
Instead of standard TFLite, Veil will use the **MediaPipe LLM Inference API** to run a highly quantized, small-parameter LLM (like Gemma 2B or Llama-3-8B-Instruct quantized to INT4).
- **Function**: Acts solely as a chat interface. It interprets user intents, reads the local SQLite database of transactions, and answers financial questions in natural language.
- **Privacy**: Runs 100% locally. Zero server costs, total data privacy.
- **Limitation**: The LLM's output is **not** cryptographically proven. It's just for the user's UX.
- **Storage**: The model weights (~1.5GB to 2GB) must be downloaded post-installation, as they exceed app store limits.

### 2. The Verification Layer (ONNX + EZKL)
When the user wants to claim a reward (e.g., clicking "Generate Proof"), the LLM hands off the process to a secondary, much smaller ML model.
- **Function**: A lightweight model (e.g., Logistic Regression, Decision Tree, or a small Neural Network) exported in the `.onnx` format. 
- **Process**: This model takes specific private financial features (e.g., `monthly_spending`, `average_transaction_value`), outputs a boolean or score, and is compiled into a ZK circuit using `EZKL`.
- **Proof Generation**: Because this model is tiny, generating a `SNARK` proof of its execution takes mere seconds on a modern mobile device.

## Application Flow

```text
1. User Query
   "Do I qualify for the Shopify Cashback?"
          ↓
2. PrivatePilot (Local LLM via MediaPipe)
   Analyzes query, checks local SQLite data, 
   replies: "Yes, based on your spending, you qualify."
          ↓
3. User Action
   User clicks [Generate Proof]
          ↓
4. zkML Execution (ONNX + EZKL)
   - Extracts exact features needed (e.g., spending < $200).
   - Runs the small ONNX model locally.
   - EZKL generates the ZK proof.
          ↓
5. Smart Contract Verification
   Proof is sent on-chain to the `ProofVerifier` contract.
          ↓
6. Payout
   Verified claim triggers a shielded RAILGUN payment.
```

## Implementation Steps (Future Phases)
1. **MediaPipe Setup**: Integrate the `mediapipe_genai` or similar Flutter wrapper to load local `.bin` or `.task` LLM files.
2. **Model Delivery**: Implement a background downloader for the LLM weights inside the app.
3. **Data Pipeline**: Ensure the local SQLite database can be effectively queried and summarized to fit into the local LLM's context window.
4. **Handoff Mechanism**: Wire the chat interface so that specific intents (like "Claim Reward") programmatically trigger the ZK proof generation flow with the correct small ONNX model parameters.

## The LLM Size Problem & Alternatives

As mentioned above, even a heavily quantized 2B-parameter LLM (like Gemma 2B) takes up roughly **1.5 GB to 2 GB** of disk space. 

**Why is this a problem?**
* **App Store Limits:** The Google Play Store and Apple App Store have initial download limits (typically ~150MB to 200MB). You cannot bundle a 1.5GB model directly into the app binary.
* **Onboarding Friction:** Users would have to download the 1.5GB model upon opening the app for the first time. Many users will abandon the app if forced to wait for a massive download on mobile data.
* **Hardware Restrictions:** Even if downloaded, older phones lack the RAM to run it, causing the app to crash.

### How were we going to do it earlier?
In the original `Privio_From_Scratch.md` and `viel_implementation_plan.md` architecture, **there was no conversational LLM.** 

`PrivatePilot` was originally designed as a **deterministic local analytics engine**. 
Instead of chatting, the app would use standard Dart/Flutter logic to sum up transactions from the local SQLite database. Then, it would pass those numerical features (e.g., `total_spending = 17420`) into a tiny, traditional machine learning model (like **Logistic Regression**).
* **Size of Logistic Regression ONNX model:** ~50 Kilobytes (KB).
* **Speed:** Instantaneous.
* **UX:** Instead of typing questions in a chat, users would just click buttons on a dashboard to see their eligibility and generate proofs.

### Alternatives for the Chat UX
If you still want the "Chat with PrivatePilot" experience, here are the alternatives:

1. **Tiny Language Models (SLMs):** Use a model like **Qwen1.5-0.5B** or **TinyLlama**. These can be quantized down to ~350MB. It's still a post-install download, but much faster. However, their reasoning abilities are significantly worse than a 2B+ model.
2. **Cloud LLM (Compromises Privacy):** You send the user's questions to an API (like OpenAI). To protect privacy, you only send *metadata* or *anonymized summaries*, never raw transactions. (e.g., "The user spent $500 on food. Can they get the reward?"). This breaks the "100% offline" promise but makes the app incredibly lightweight.
3. **Revert to the Original Plan (No Chat):** Remove the Generative AI chat entirely. Replace the PrivatePilot screen with a sleek "Analytics & Eligibility" dashboard where users can run local rules against their data instantly using a tiny 50KB ONNX model.

## The Verification Layer: ONNX + EZKL vs Alternatives

The Verification Layer is responsible for taking the private inputs (e.g., financial aggregates) and running them through a verifiable computation to generate a Zero-Knowledge (ZK) proof, which is then verified on-chain.

### Current Approach: ONNX + EZKL
**EZKL** (Easy Zero-Knowledge Learning) is an engine that takes a standard `.onnx` machine learning model and automatically compiles it into a ZK-SNARK circuit. 

**Pros:**
* **Developer Experience:** You don't have to write custom cryptographic circuits. You train a model in Python (scikit-learn/PyTorch), export it to ONNX, and EZKL handles the complex cryptography automatically.
* **Flexibility:** Supports a wide range of standard ML operations out-of-the-box.
* **EVM Compatibility:** EZKL generates a Solidity Verifier contract that you can deploy directly to Ethereum.

**Cons / Feasibility Issues on Mobile:**
* **Mobile Integration:** Running the EZKL prover (which is written in Rust) directly inside a Flutter app on iOS/Android requires complex FFI (Foreign Function Interface) bindings. While theoretically possible, it is technically challenging to set up and maintain.
* **Computational Overhead:** Proving is computationally heavy. While a 50KB ONNX model is instantaneous to *evaluate*, *proving* it in a SNARK circuit takes significantly more RAM and CPU time. On older mobile devices, generating the proof could take several seconds and drain the battery.

### Are there better options out there?

If the "ML model" aspect isn't strictly necessary and the logic is just basic math (e.g., `if total_spending < 20000 then true`), using a full zkML engine like EZKL is overkill. Here are the alternatives:

#### 1. Circom + SnarkJS (The Industry Standard for Mobile)
Circom is a language for writing ZK circuits, and SnarkJS is a library that can run the prover.
* **Pros:** Highly optimized and lightweight. This is the technology used by major projects (like Tornado Cash or Semaphore). It is widely battle-tested, incredibly fast, and runs easily on mobile phones (either via native wrappers or a hidden webview).
* **Cons:** You have to manually write the circuit in the Circom language. You are writing mathematical constraints, not standard code or ML models.
* **Feasibility for Veil:** If your eligibility rules are simple mathematical checks (e.g., verifying a number is `<` or `>`), writing a Circom circuit takes very little time and will run flawlessly on mobile. **This is the safest bet for production.**

#### 2. Noir (by Aztec)
Noir is a modern, Rust-like language for writing ZK circuits. 
* **Pros:** Much easier to write and read than Circom. Excellent tooling. Compiles down to highly efficient proofs.
* **Cons:** The ecosystem is newer, though mobile proving support is rapidly improving.

#### 3. General-Purpose zkVMs (RISC Zero / SP1)
Instead of converting an ML model or writing a circuit, you write standard Rust code (e.g., `fn check_eligibility() { ... }`), and the zkVM compiles the execution of that Rust program into a ZK proof.
* **Pros:** Unmatched flexibility. You just write normal code.
* **Cons:** The proving overhead for zkVMs is currently enormous. Running a full zkVM prover natively on a mobile device is highly experimental and too resource-intensive for a consumer mobile app today.

### Conclusion & Recommendation for Veil
* **If you strictly need Machine Learning (e.g., fuzzy logic, risk scoring):** Stick with **ONNX + EZKL**. It is the most robust zkML tool, but you must prepare for a challenging Flutter FFI integration to run the Rust prover on-device.
* **If the logic is deterministic rules (e.g., `spending < $200`):** **Drop EZKL**. Write a simple circuit in **Circom** or **Noir**. It will be 100x faster, consume almost no battery, and integrate far more easily into a Flutter mobile app.
