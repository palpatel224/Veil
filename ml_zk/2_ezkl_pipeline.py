"""
2_ezkl_pipeline.py
------------------
Runs the full EZKL zkML pipeline on top of the exported `eligibility_model.onnx`
to produce a Halo2 ZK circuit, proving/verification keys, a ZK proof of the
model's eligibility decision, and a deployable EVM Solidity verifier contract.

Pipeline steps:
    a. gen_settings          -> settings.json
    b. calibrate_settings    -> settings.json (calibrated)
    c. compile_circuit       -> network.ezkl
    d. get_srs               -> kzg.srs               (async)
    e. setup                 -> vk.key, pk.key
    f. gen_witness           -> witness.json
    g. prove                 -> proof.json
    h. verify                -> off-chain proof check
    i. create_evm_verifier   -> Verifier.sol           (async)

Note: EZKL's Python bindings mix synchronous calls with a couple of Rust
async (Tokio) calls (`get_srs`, `create_evm_verifier`). Those two must be
awaited from within a running asyncio event loop; the rest are plain
blocking calls.
"""

import asyncio
import os

import ezkl

MODEL_PATH = "eligibility_model.onnx"
DATA_PATH = "input.json"
SETTINGS_PATH = "settings.json"
COMPILED_CIRCUIT_PATH = "network.ezkl"
SRS_PATH = "kzg.srs"
VK_PATH = "vk.key"
PK_PATH = "pk.key"
WITNESS_PATH = "witness.json"
PROOF_PATH = "proof.json"
SOL_CODE_PATH = "Verifier.sol"
ABI_PATH = "Verifier.abi"


def _checkpoint(step, message):
    print(f"\n[{step}] {message}")


async def main():
    for required in (MODEL_PATH, DATA_PATH):
        if not os.path.exists(required):
            raise FileNotFoundError(
                f"Missing '{required}'. Run 1_train_export.py first."
            )

    # a. Generate default circuit settings from the ONNX model.
    _checkpoint("a", "Generating circuit settings...")
    res = ezkl.gen_settings(model=MODEL_PATH, output=SETTINGS_PATH)
    assert res, "gen_settings failed"
    print(f"✅ settings generated: {SETTINGS_PATH}")

    # b. Calibrate settings using a representative input for numerical scaling.
    _checkpoint("b", "Calibrating settings against sample input...")
    res = ezkl.calibrate_settings(
        data=DATA_PATH,
        model=MODEL_PATH,
        settings=SETTINGS_PATH,
        target="resources",
    )
    assert res, "calibrate_settings failed"
    print(f"✅ settings calibrated: {SETTINGS_PATH}")

    # c. Compile the ONNX model + settings into an EZKL circuit.
    _checkpoint("c", "Compiling circuit...")
    res = ezkl.compile_circuit(
        model=MODEL_PATH,
        compiled_circuit=COMPILED_CIRCUIT_PATH,
        settings_path=SETTINGS_PATH,
    )
    assert res, "compile_circuit failed"
    print(f"✅ circuit compiled: {COMPILED_CIRCUIT_PATH}")

    # d. Fetch/generate the KZG Structured Reference String (async call).
    _checkpoint("d", "Fetching Structured Reference String (SRS)...")
    res = await ezkl.get_srs(srs_path=SRS_PATH, settings_path=SETTINGS_PATH)
    assert res, "get_srs failed"
    print(f"✅ SRS ready: {SRS_PATH}")

    # e. Run trusted setup to generate proving/verification keys.
    _checkpoint("e", "Running setup (generating vk.key / pk.key)...")
    res = ezkl.setup(
        model=COMPILED_CIRCUIT_PATH,
        vk_path=VK_PATH,
        pk_path=PK_PATH,
        srs_path=SRS_PATH,
    )
    assert res, "setup failed"
    print(f"✅ setup complete: {VK_PATH}, {PK_PATH}")

    # f. Generate the private witness from the sample input.
    _checkpoint("f", "Generating witness...")
    res = ezkl.gen_witness(
        data=DATA_PATH,
        model=COMPILED_CIRCUIT_PATH,
        output=WITNESS_PATH,
    )
    assert res, "gen_witness failed"
    print(f"✅ witness generated: {WITNESS_PATH}")

    # g. Generate the ZK proof.
    _checkpoint("g", "Generating ZK proof...")
    res = ezkl.prove(
        witness=WITNESS_PATH,
        model=COMPILED_CIRCUIT_PATH,
        pk_path=PK_PATH,
        proof_path=PROOF_PATH,
        srs_path=SRS_PATH,
    )
    assert res, "prove failed"
    print(f"✅ proof generated: {PROOF_PATH}")

    # h. Verify the proof off-chain.
    _checkpoint("h", "Verifying proof off-chain...")
    res = ezkl.verify(
        proof_path=PROOF_PATH,
        settings_path=SETTINGS_PATH,
        vk_path=VK_PATH,
        srs_path=SRS_PATH,
    )
    assert res, "Off-chain proof verification FAILED"
    print("✅ proof verified off-chain successfully")

    # i. Generate the Solidity EVM verifier contract (async call, requires solc).
    _checkpoint("i", "Generating EVM Solidity verifier contract...")
    res = await ezkl.create_evm_verifier(
        vk_path=VK_PATH,
        settings_path=SETTINGS_PATH,
        sol_code_path=SOL_CODE_PATH,
        abi_path=ABI_PATH,
        srs_path=SRS_PATH,
    )
    assert res, "create_evm_verifier failed"
    print(f"✅ Solidity verifier generated: {SOL_CODE_PATH}")

    print("\n🎉 EZKL pipeline completed successfully!")


if __name__ == "__main__":
    asyncio.run(main())
