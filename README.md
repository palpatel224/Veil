# Veil

Veil is a privacy-preserving conditional payment and rewards platform. It enables users to verify their eligibility for programs (like cashbacks, scholarships, and grants) and generate zero-knowledge proofs completely locally on their device. 

## Features
- **PrivatePilot**: An on-device assistant that scans local data (financial, academic, etc.) to check program eligibility without exposing sensitive information.
- **ZK Proofs**: Cryptographically prove conditions without revealing the underlying data.
- **Programs Marketplace**: Discover cashbacks, grants, and refunds that respect your privacy.
- **Shielded Wallet**: Keep track of private balances and verifiable claims.

## Tech Stack
- **Frontend**: Flutter (Mobile & Web)
- **Design System**: Custom dark-mode minimalist UI with glassmorphism touches (#7153E7 purple, #BBE753 lime)
- **Future Integration**: Foundary/Solidity (Smart Contracts), ONNXRuntime (Local ML), Railgun (Shielded payments).

## Getting Started

To run the Flutter app locally:

1. Ensure you have Flutter installed.
2. Navigate to the app directory:
   ```bash
   cd viel
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Architecture
The platform follows a **Prove → Verify → Pay** model:
1. **Prove**: The app uses local data to generate a zero-knowledge proof.
2. **Verify**: The blockchain/backend verifies the proof cryptographically.
3. **Pay**: The user receives the reward in a shielded transaction.
