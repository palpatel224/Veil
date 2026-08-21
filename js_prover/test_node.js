import * as ezkl from '@ezkljs/engine';
import fs from 'fs';
import path from 'path';

async function main() {
    console.log("Initializing EZKL for Node test...");
    
    // Define paths
    const basePath = path.join(process.cwd(), '../ml_zk');
    const inputPath = path.join(basePath, 'input.json');
    const networkPath = path.join(basePath, 'network.ezkl');
    const pkPath = path.join(basePath, 'pk.key');
    const srsPath = path.join(basePath, 'kzg.srs');

    // Check if artifacts exist
    if (!fs.existsSync(inputPath)) {
        console.error("Artifacts not found in ml_zk/");
        process.exit(1);
    }

    console.log("Loading files into memory...");
    const inputBuffer = fs.readFileSync(inputPath);
    const networkBuffer = fs.readFileSync(networkPath);
    const pkBuffer = fs.readFileSync(pkPath);
    const srsBuffer = fs.readFileSync(srsPath);

    const inputData = new Uint8ClampedArray(inputBuffer);
    const networkData = new Uint8ClampedArray(networkBuffer);
    const pkData = new Uint8ClampedArray(pkBuffer);
    const srsData = new Uint8ClampedArray(srsBuffer);

    console.log("Generating witness...");
    const witnessBuffer = ezkl.genWitness(networkData, inputData);
    const witnessData = new Uint8ClampedArray(witnessBuffer);

    console.log("Generating proof...");
    const proofBuffer = ezkl.prove(witnessData, pkData, networkData, srsData);
    
    const proofJson = new TextDecoder().decode(proofBuffer);
    const proofObj = JSON.parse(proofJson);
    console.log("✅ Proof generated successfully!");
    console.log("Proof Hex String starts with:", proofObj.hex_proof.substring(0, 60) + "...");
}

main().catch(console.error);
