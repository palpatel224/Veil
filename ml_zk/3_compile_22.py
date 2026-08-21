import ezkl

res = ezkl.compile_circuit(
    model="eligibility_model.onnx",
    compiled_circuit="network.ezkl",
    settings_path="settings.json",
)
print("compile_circuit returned:", res)
