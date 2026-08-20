#!/usr/bin/env bash
# run_all.sh
# Master runner (shell version): sets up a virtual environment, installs
# dependencies, then runs the full training + EZKL zkML pipeline.
set -e

cd "$(dirname "$0")"

echo "============================================================"
echo "Privio — Eligibility Model -> ONNX -> EZKL Pipeline"
echo "============================================================"

if [ ! -d ".venv" ]; then
  echo "--- Creating virtual environment (.venv) ---"
  python3 -m venv .venv
fi

source .venv/bin/activate

echo "--- Installing dependencies ---"
pip install --upgrade pip >/dev/null
pip install -r requirements.txt

echo "--- Step 1/2: Training & exporting ONNX model ---"
python 1_train_export.py

echo "--- Step 2/2: Running EZKL zkML pipeline ---"
python 2_ezkl_pipeline.py

echo "============================================================"
echo "Pipeline finished. Artifacts:"
for f in eligibility_model.onnx input.json settings.json network.ezkl kzg.srs vk.key pk.key witness.json proof.json Verifier.sol; do
  if [ -f "$f" ]; then
    echo "  [OK]   $f"
  else
    echo "  [MISS] $f"
  fi
done
echo "============================================================"
