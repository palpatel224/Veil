# Zero-Knowledge Signature Verification Architecture

## 1. The Threat Model: Local Database Spoofing
In a traditional Web2 architecture, a centralized server holds the data and acts as the source of truth. In Veil's **Local-First ZK Architecture**, the user's mobile device acts as the source of truth, storing data in a local SQLite database (the Secure Enclave).

**The Vulnerability:**
A malicious user could root their Android/iOS device, open the Veil SQLite database, and manually alter their metrics (e.g., changing `total_balance` from `$100` to `$1,000,000`). If the Noir circuit only checks `assert(user_balance >= min_balance)`, the circuit will generate a valid cryptographic proof based on the falsified data. The blockchain would accept this proof, allowing the user to fraudulently claim rewards.

## 2. The Solution: Cryptographic Data Provenance
To solve this, we must shift the source of truth from the *database values* to the *cryptographic signatures* attached to those values.

Whenever data is imported into Veil:
1. **zkTLS (Web APIs):** Protocols like Reclaim generate an **ECDSA signature** asserting that specific data was fetched from a specific HTTPS endpoint (e.g., `api.github.com`).
2. **Govt ID (Aadhaar/e-PAN):** The Indian government signs Aadhaar XML data using an **RSA-2048 signature**.

The Noir Zero-Knowledge circuit must verify these signatures *before* evaluating the program rules. 

## 3. Noir Cryptographic Primitives
Noir's standard library (`std`) and community libraries provide the necessary tools to verify these signatures natively inside the circuit.

### A. zkTLS / Reclaim Protocol (ECDSA)
Reclaim Protocol attesters sign the data payloads using `secp256k1` ECDSA.
Noir natively supports this via the standard library:
```rust
use std::ecdsa_secp256k1;

// The circuit verifies the Reclaim Node's public key signed the hashed data payload
let is_valid = ecdsa_secp256k1::verify_signature(public_key_x, public_key_y, signature, hashed_payload);
assert(is_valid);
```

### B. Govt XML / Aadhaar (RSA-2048)
Aadhaar XMLs are signed using RSA-2048 with SHA-256. RSA involves large integer arithmetic (BigInt), which is historically heavy for ZK circuits.
We will utilize community Noir libraries (like `noir-rsa` or BigInt implementations) to verify the PKCS#1 v1.5 padding and the RSA signature against the UIDAI public root certificate.

## 4. The Updated Universal Circuit Flow
To secure Veil, the `main.nr` circuit will be expanded to take the signature arrays as private inputs.

### The Conceptual Circuit Update
```rust
use std::ecdsa_secp256k1;
use std::hash::sha256;

fn main(
    // Public Inputs (What the Smart Contract sees)
    min_balance: pub u64,
    trusted_attester_pub_key_x: pub [u8; 32],
    trusted_attester_pub_key_y: pub [u8; 32],
    
    // Private Inputs (From Local SQLite)
    user_balance: u64,
    zkTLS_signature: [u8; 64],
    raw_api_payload: [u8; 512], // The raw JSON string from the bank
) {
    // STEP 1: PROVENANCE VERIFICATION
    // Hash the raw payload
    let payload_hash = sha256(raw_api_payload);
    
    // Verify the zkTLS attester actually signed this exact payload
    let is_authentic = ecdsa_secp256k1::verify_signature(
        trusted_attester_pub_key_x, 
        trusted_attester_pub_key_y, 
        zkTLS_signature, 
        payload_hash
    );
    assert(is_authentic); // If user tampered with SQLite, this fails instantly.

    // STEP 2: DATA EXTRACTION
    // (Logic to safely parse the `user_balance` out of the raw_api_payload string)
    // assert(extracted_balance == user_balance);
    
    // STEP 3: RULE EVALUATION
    // Finally, verify the user meets the grant requirements
    assert(user_balance >= min_balance);
}
```

## 5. Security Guarantees Achieved
By implementing this architecture:
1. **Zero-Knowledge:** The blockchain only sees the `trusted_attester_pub_key` and the `min_balance`. It never learns the user's actual balance or the raw API payload.
2. **Anti-Tampering:** If a user modifies their SQLite database, the `sha256(raw_api_payload)` will change. The ECDSA signature will no longer match the hash, causing the `assert(is_authentic)` to fail. The proof generation will abort locally.
3. **True Local-First:** The user remains in complete control of their data, and the platform remains mathematically secure.
