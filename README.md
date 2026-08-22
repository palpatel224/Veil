# Veil

Veil is a privacy-first Web3 conditional payment and rewards platform. It completely flips the paradigm of traditional data sharing: instead of users uploading their sensitive personal, financial, or academic data to third-party servers for evaluation, Veil brings the evaluation rules directly to the user's device.

Using a conversational AI assistant (**PrivatePilot**), users fetch their local data, run a lightweight Machine Learning model *entirely on-device*, and generate a Zero-Knowledge Proof (zkML). This cryptographically guarantees the user meets eligibility criteria without ever exposing their actual financial data. The proof is verified by an Ethereum smart contract, triggering a shielded payment.

## Features

- **PrivatePilot**: An on-device intent-parsing AI assistant that scans local data and checks program eligibility in an intuitive, chat-like interface without violating user privacy.
- **zkML & ZK Proofs**: Powered by EZKL, ONNX, and Halo2, Veil proves ML inferences and complex rule validations cryptographically on-device.
- **Programs Marketplace**: Discover cashbacks, grants, alpha testing, and refunds that respect your privacy.
- **Shielded Payments**: Rewards are received via shielded transactions (Railgun infrastructure) ensuring complete financial anonymity.
- **Premium UI/UX**: Built with Flutter, the app features a cypherpunk-inspired, dark-mode minimalist UI with glassmorphism touches and smooth animations to abstract away cryptographic overhead.

## Technologies Used

- **Flutter (Dart)**: Cross-platform mobile client, conversational AI interface, and local proof generation UX.
- **Solidity & Foundry**: For the `VeilRegistry` and on-chain ZK `Verifier` smart contracts.
- **EZKL / Halo2**: To convert ONNX Machine Learning models into Zero-Knowledge circuits.
- **Python (PyTorch / ONNX)**: For training the financial eligibility models.
- **Noir (Barretenberg)**: For writing universal rule engine circuits.
- **TypeScript (Railgun SDK)**: For setting up the shielded payment flows.

## Architecture Pipeline

The platform follows a **Prove → Verify → Pay** model:
1. **Prove**: The app uses the local ML model to evaluate eligibility against local data and generates a Zero-Knowledge Proof (via EZKL/Noir).
2. **Verify**: The generated proof is submitted on-chain, where the `VeilRegistry` contract verifies it cryptographically.
3. **Pay**: Upon successful verification, the smart contract triggers a shielded payment (via Railgun) directly to the user's private wallet.

## Getting Started

To run the Flutter mobile application locally:

1. Ensure you have [Flutter](https://docs.flutter.dev/get-started/install) installed.
2. Clone the repository and navigate to the mobile app directory:
   ```bash
   cd viel
   ```
3. Get the dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```
