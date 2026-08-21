# Veil — Eligibility Model → ONNX → EZKL (zkML) Pipeline

This workspace implements the AI/ML + ZK layer described in `../Veil.md`: a
lightweight Logistic Regression eligibility model, exported to ONNX, proven
with EZKL as a Halo2 zero-knowledge circuit, and verifiable on-chain via a
generated Solidity verifier contract.

## Files

| File                 | Purpose                                                                                                                       |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `requirements.txt`   | Python dependencies (torch, numpy, onnx, onnxscript, ezkl)                                                                    |
| `1_train_export.py`  | Trains `EligibilityModel` (Logistic Regression, 4 inputs) and exports `eligibility_model.onnx` + `input.json`                 |
| `2_ezkl_pipeline.py` | Runs the full EZKL pipeline: settings → calibration → circuit compile → SRS → setup → witness → proof → verify → EVM verifier |
| `run_pipeline.py`    | Master runner (Python) — runs both scripts in sequence with status checkpoints                                                |
| `run_all.sh`         | Master runner (shell) — creates a venv, installs deps, and runs the full pipeline                                             |

## Use case

This is the zkML layer behind Veil's **"prove eligibility without revealing
your data"** flow. Instead of a user sending raw financial data (spending,
transaction history, income) to a server to check if they qualify for
something — a cashback offer, a refund, a grant, a loyalty reward — the
eligibility check runs locally as an ML model, and only a **zero-knowledge
proof of the result** ("eligible" / "not eligible") is shared. The verifier
(a smart contract on Ethereum) checks the proof and authorizes a conditional
payout, without ever seeing the user's actual financial data.

```
User's private financial data
        ↓
EligibilityModel runs locally (this folder)
        ↓
ZK proof generated (EZKL / Halo2)
        ↓
Proof + Verifier.sol checked on-chain
        ↓
Conditional payment released (no raw data exposed)
```

## Model

Inputs (normalized 0–1 range, ZK-circuit friendly):

1. Feature 0 — Normalized Monthly Spending (e.g. ₹17,420 → 0.1742)
2. Feature 1 — Normalized Average Transaction Size (e.g. ₹500 → 0.050)
3. Feature 2 — Transaction Count ratio (e.g. 25 tx → 0.25)
4. Feature 3 — Normalized Monthly Income (e.g. ₹60,000 → 0.60)

Label: `Eligible = 1` if Monthly Spending < ₹40,000 (feature 0 < 0.40), else `0`.

## How it works (pipeline)

1. **`1_train_export.py`** — trains the logistic regression model on
   synthetic data, then exports it to `eligibility_model.onnx` (ONNX opset 14)
   along with a sample `input.json` used for calibration/witness generation.
2. **`2_ezkl_pipeline.py`** — feeds the ONNX model into EZKL to produce a
   Halo2 ZK circuit: generates/calibrates settings, compiles the circuit,
   fetches the KZG SRS, runs trusted setup (proving/verification keys),
   generates a witness + proof from the sample input, verifies the proof
   off-chain, and finally emits `Verifier.sol` — a Solidity contract that lets
   Ethereum verify the proof on-chain.
3. **`run_pipeline.py`** / **`run_all.sh`** — run both steps end-to-end and
   report which artifacts were produced.

The result: a user can prove "my spending qualifies me for this reward"
without ever revealing their spending, transaction, or income figures to
anyone — only the proof and the pass/fail claim are shared.

## Quick start

```bash
cd ml_zk
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# solc is required for the EVM verifier generation step (create_evm_verifier)
pip install solc-select
solc-select install 0.8.20 && solc-select use 0.8.20

python run_pipeline.py
# or: ./run_all.sh
```

## Generated artifacts

Running the pipeline produces (in order):

- `eligibility_model.onnx` — trained model in ONNX (opset 14)
- `input.json` — sample witness input `[[0.1742, 0.050, 0.25, 0.60]]`
- `settings.json` — calibrated EZKL circuit settings
- `network.ezkl` — compiled Halo2 circuit
- `kzg.srs` — KZG Structured Reference String
- `vk.key` / `pk.key` — verification / proving keys
- `witness.json` — private witness (model forward pass trace)
- `proof.json` — the ZK proof + public instances
- `Verifier.sol` / `Verifier.abi` — deployable EVM Halo2 verifier contract

## Verified correctness

- Off-chain proof verification (`ezkl.verify`) passes (`True`).
- The witness's rescaled output matches the plain PyTorch model's own forward
  pass on the same input; the tiny difference is expected fixed-point
  quantization from the ZK circuit's scale factors.
- Sample input (Monthly Spending 0.1742 < 0.40 threshold) correctly yields an
  eligibility score > 0.5 → **Eligible**, matching the labeling rule and the
  "Spend below a threshold → cashback/eligible" scenario in `../Veil.md`.
- `Verifier.sol` compiles successfully with `solc 0.8.20`
  (`--optimize --optimize-runs 1`), confirming it is valid, deployable
  Solidity.

## Notes on the EZKL Python API

A couple of `ezkl` bindings are async (Rust/Tokio-backed) and must be
`await`-ed inside a running event loop: `get_srs` and `create_evm_verifier`.
The rest of the pipeline calls (`gen_settings`, `calibrate_settings`,
`compile_circuit`, `setup`, `gen_witness`, `prove`, `verify`) are plain
blocking calls. `2_ezkl_pipeline.py` handles this correctly via
`asyncio.run(main())`.
