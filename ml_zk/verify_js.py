import ezkl

res = ezkl.verify(
    proof_path="proof_js.json",
    settings_path="settings.json",
    vk_path="vk.key",
    srs_path="kzg.srs",
)
print("Verify returned:", res)
