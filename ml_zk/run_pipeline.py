#!/usr/bin/env python3
"""
run_pipeline.py
----------------
Master runner for the Privio eligibility model + EZKL zkML pipeline.
Runs training/export followed by the full EZKL circuit/proof/verifier
generation, printing status checkpoints and failing fast on any error.
"""

import subprocess
import sys

STEPS = [
    ("Training & exporting ONNX model", ["python3", "1_train_export.py"]),
    ("Running EZKL zkML pipeline", ["python3", "2_ezkl_pipeline.py"]),
]


def run():
    print("=" * 60)
    print("Privio — Eligibility Model → ONNX → EZKL Pipeline")
    print("=" * 60)

    for i, (description, cmd) in enumerate(STEPS, start=1):
        print(f"\n--- Step {i}/{len(STEPS)}: {description} ---")
        result = subprocess.run(cmd)
        if result.returncode != 0:
            print(f"\n❌ Step {i} failed: {description}")
            sys.exit(result.returncode)
        print(f"✅ Step {i} complete: {description}")

    print("\n" + "=" * 60)
    print("🎉 Pipeline finished successfully!")
    print("Artifacts generated:")
    for artifact in (
        "eligibility_model.onnx",
        "input.json",
        "settings.json",
        "network.ezkl",
        "kzg.srs",
        "vk.key",
        "pk.key",
        "witness.json",
        "proof.json",
        "Verifier.sol",
    ):
        print(f"  - {artifact}")
    print("=" * 60)


if __name__ == "__main__":
    run()
