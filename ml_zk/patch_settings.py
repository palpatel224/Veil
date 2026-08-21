import json

with open("settings.json", "r") as f:
    data = json.load(f)

data["run_args"]["logrows"] = 17

with open("settings.json", "w") as f:
    json.dump(data, f)
print("Patched settings.json to logrows 17")
