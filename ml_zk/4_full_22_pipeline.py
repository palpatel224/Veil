import ezkl
import asyncio

async def main():
    # 1. Compile circuit
    ezkl.compile_circuit(
        model="eligibility_model.onnx",
        compiled_circuit="network.ezkl",
        settings_path="settings.json"
    )
    print("Compiled circuit with 22.0.1")

    # 2. Setup
    ezkl.setup(
        model="network.ezkl",
        vk_path="vk.key",
        pk_path="pk.key",
        srs_path="kzg.srs"
    )
    print("Setup completed with 22.0.1")

    # 3. Witness
    ezkl.gen_witness(
        data="input.json",
        model="network.ezkl",
        output="witness.json"
    )
    print("Witness generated with 22.0.1")

    # 4. Prove
    ezkl.prove(
        witness="witness.json",
        model="network.ezkl",
        pk_path="pk.key",
        proof_path="proof.json",
        srs_path="kzg.srs"
    )
    print("Proof generated with 22.0.1")

    # 5. Verify
    res = ezkl.verify(
        proof_path="proof.json",
        settings_path="settings.json",
        vk_path="vk.key",
        srs_path="kzg.srs"
    )
    print("Verify returned:", res)

    # 6. EVM Verifier
    res = await ezkl.create_evm_verifier(
        vk_path="vk.key",
        settings_path="settings.json",
        sol_code_path="Verifier.sol",
        abi_path="Verifier.abi",
        srs_path="kzg.srs"
    )
    print("create_evm_verifier returned:", res)

if __name__ == "__main__":
    asyncio.run(main())
