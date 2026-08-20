# Data Provenance in Veil: Research & Real-World Feasibility

To successfully generate Zero-Knowledge proofs for eligibility (e.g., "Income < 5 Lakh" or "GitHub PRs > 1"), Veil must first solve the **Data Provenance** problem. We must prove the data is authentic and hasn't been tampered with before feeding it into the ZK Rule Engine.

This document outlines the three primary technologies for Data Provenance, how they work, and their real-world adoption.

---

## 1. zkTLS (Zero-Knowledge Transport Layer Security)
**Best for:** Fetching web data (APIs, Dashboards, Bank Portals, GitHub).
**Leading Protocols:** Reclaim Protocol, TLSNotary.

### How it Works
When a user logs into a website (e.g., GitHub), the browser establishes a secure TLS (HTTPS) connection with the server. Normally, only the user and the server can decrypt the data. **zkTLS** uses cryptographic proxying (e.g., Multi-Party Computation or Garbled Circuits) to allow a third-party "Attestor" to verify that the server sent a specific HTTPS response, without the Attestor seeing the user's password, session cookie, or the full decrypted payload. The output is a cryptographic receipt proving the data is authentic.

### Real-World Adoption (IRL Status: Highly Active)
* **Reclaim Protocol:** Has processed over **4 million verifications** and is actively used by over 25 enterprise-level clients.
* **Use Cases IRL:**
  * **Financial Services:** DeFi lending protocols use it to verify bank balances for undercollateralized loans.
  * **Government & Enterprise:** Running pilots with **NPCI (National Payments Corporation of India)** and MOSIP (a digital identity platform used in 40+ countries).
  * **Proof of Employment/Education:** Used by Web3 platforms to verify a user's enrollment status or employment history directly from institutional portals, increasing onboarding conversion rates dramatically (e.g., from 7% to 44% in one case study).
* **Veil Application:** A user connects GitHub in the Veil app. zkTLS intercepts the `api.github.com` response showing "Merged PRs: 3", and generates a receipt. Veil feeds this receipt into the ZK Rule Engine.

---

## 2. ZK Email
**Best for:** Verifying data sent via official institutional emails (Bank statements, Receipts, University acceptances).

### How it Works
Most modern email providers (Gmail, Outlook, Yahoo) sign outgoing emails with a **DKIM (DomainKeys Identified Mail)** digital signature to prevent spam/spoofing. ZK Email uses a Zero-Knowledge circuit to verify this RSA DKIM signature. The circuit can use regular expressions (Regex) to extract specific text (e.g., "Your salary of Rs. 50,000 has been credited") while hiding the rest of the email (sender address, name, account numbers).

### Real-World Adoption (IRL Status: Production Ready)
* **Smart Account Recovery:** Wallets (like Safe or Argent) use ZK Email for social recovery. If you lose your crypto keys, you can email a smart contract to prove ownership of your email address and recover funds.
* **ZKP2P (Fiat-to-Crypto Onramps):** ZKP2P is a live marketplace where users trade fiat for crypto trustlessly. When a user sends fiat via Venmo or UPI, the bank sends an email receipt. ZK Email verifies the DKIM signature on that receipt and automatically releases the crypto on-chain.
* **Veil Application:** If a scholarship requires proof of income, the user forwards their bank statement email to the app. The app verifies the Bank's DKIM signature locally and proves the income is below the required threshold.

---

## 3. Aadhaar Paperless Offline e-KYC (XML Signatures)
**Best for:** Identity verification, Nationality, Age, and Demographics in India.

### How it Works (PKI, not natively ZK)
Currently, UIDAI provides an "Offline e-KYC" mechanism. A user downloads a ZIP file containing an XML document with their demographic data. 
* **The Provenance:** This XML file is **digitally signed** by UIDAI using standard PKI (Public Key Infrastructure) RSA signatures. 
* Any verifier can check this signature using UIDAI's public certificate to ensure the data is untampered. 

### Bridging Aadhaar XML with ZK
In the standard Aadhaar offline process, you hand over the entire XML (revealing your Aadhaar number, name, and address). To make this Zero-Knowledge for Veil:
1. The user downloads the signed Aadhaar XML to their phone.
2. The Veil App loads a ZK Circuit containing UIDAI's public key.
3. The circuit verifies the RSA digital signature *internally*.
4. The circuit extracts only the required data (e.g., calculating Age from the Date of Birth) and proves `Age > 18`.
5. The output proof verifies the Aadhaar signature and the age rule, without revealing the Aadhaar number itself.

### Real-World Adoption (IRL Status: Evolving)
* The standard offline XML signature is an official, government-sanctioned process used by hundreds of Indian fintechs for KYC.
* **ZK Wrappers:** Several Web3 identity protocols (like AnonAadhaar) are actively building and auditing ZK circuits specifically designed to verify the Indian Government's RSA signature on these XML files, enabling anonymous Proof-of-Citizenship on Ethereum.

---

### Conclusion for Veil
The technology for Data Provenance is entirely mature and actively used in production today. By combining **Reclaim Protocol (zkTLS)** for dynamic web data and **ZK Email/Digital Signatures** for static documents, Veil can securely fetch the authentic inputs required for its Universal Rule Engine.
