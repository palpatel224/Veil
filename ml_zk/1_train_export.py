"""
1_train_export.py
------------------
Trains a lightweight Logistic Regression "EligibilityModel" for Privio's
privacy-preserving financial conditional payments platform, then exports it
to ONNX (opset 14) so it can be fed into the EZKL zkML pipeline.

Inputs (all normalized to a 0-1 style range so the model is friendly to
fixed-point ZK circuits):
    Feature 0: Normalized Monthly Spending      (e.g. Rs.17,420 -> 0.1742)
    Feature 1: Normalized Average Transaction   (e.g. Rs.500    -> 0.050)
    Feature 2: Transaction Count ratio          (e.g. 25 tx     -> 0.25)
    Feature 3: Normalized Monthly Income        (e.g. Rs.60,000 -> 0.60)

Label:
    Eligible (1) if Monthly Spending < Rs.40,000 (i.e. feature 0 < 0.40)
    Not Eligible (0) otherwise
"""

import json

import numpy as np
import torch
import torch.nn as nn


class EligibilityModel(nn.Module):
    """Single-layer Logistic Regression classifier over 4 financial features."""

    def __init__(self):
        super(EligibilityModel, self).__init__()
        self.linear = nn.Linear(4, 1)
        self.sigmoid = nn.Sigmoid()

    def forward(self, x):
        return self.sigmoid(self.linear(x))


def main():
    torch.manual_seed(42)
    np.random.seed(42)

    model = EligibilityModel()

    # 1. Synthetic training data.
    # label = 1 (Eligible) if Feature 0 (Monthly Spending) < 0.40 (Rs.40,000 threshold)
    n_samples = 500
    X_train = np.random.rand(n_samples, 4).astype(np.float32)
    y_train = (X_train[:, 0] < 0.40).astype(np.float32).reshape(-1, 1)

    X_tensor = torch.from_numpy(X_train)
    y_tensor = torch.from_numpy(y_train)

    # 2. Train with BCE loss + Adam optimizer.
    criterion = nn.BCELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=0.05)

    epochs = 300
    for epoch in range(epochs):
        optimizer.zero_grad()
        predictions = model(X_tensor)
        loss = criterion(predictions, y_tensor)
        loss.backward()
        optimizer.step()
        if (epoch + 1) % 50 == 0:
            print(f"Epoch {epoch + 1}/{epochs} - loss: {loss.item():.4f}")

    model.eval()

    # Quick sanity check on training accuracy.
    with torch.no_grad():
        preds = (model(X_tensor) > 0.5).float()
        accuracy = (preds == y_tensor).float().mean().item()
    print(f"✅ Training accuracy: {accuracy * 100:.2f}%")

    # 3. Export to ONNX (opset 14).
    dummy_input = torch.tensor([[0.1742, 0.050, 0.25, 0.60]], dtype=torch.float32)
    onnx_filename = "eligibility_model.onnx"

    torch.onnx.export(
        model,
        dummy_input,
        onnx_filename,
        export_params=True,
        opset_version=14,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={"input": {0: "batch_size"}, "output": {0: "batch_size"}},
        dynamo=False,
    )
    print(f"✅ ONNX model exported: {onnx_filename}")

    # 4. Export a matching test sample for EZKL calibration/witness generation.
    sample_input = {"input_data": [[0.1742, 0.050, 0.25, 0.60]]}
    with open("input.json", "w") as f:
        json.dump(sample_input, f)
    print("✅ Sample input exported: input.json")

    # Print what the trained model thinks of the sample input for reference.
    with torch.no_grad():
        sample_output = model(dummy_input)
    print(f"ℹ️  Sample eligibility score: {sample_output.item():.4f}")


if __name__ == "__main__":
    main()
