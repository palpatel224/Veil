import initWasm, * as ezkl from '@ezkljs/engine';

async function init() {
    console.log("Initializing EZKL...");
    await initWasm();
    if (!ezkl || !ezkl.prove) {
        throw new Error("Failed to load EZKL engine!");
    }
    console.log("EZKL Engine loaded successfully.");
}

async function fetchAsUint8Array(url) {
    console.log("Fetching " + url + "...");
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error("Failed to fetch " + url + ": " + response.statusText);
    }
    const buffer = await response.arrayBuffer();
    console.log("Fetched " + url + " (" + buffer.byteLength + " bytes)");
    return new Uint8ClampedArray(buffer);
}

// inputData should be a JS object like { "input_data": [[0.1742, 0.05, 0.25, 0.6]] }
async function generateProofFromUrls(inputDataObj) {
    try {
        console.log("Fetching artifacts...");
        const networkData = await fetchAsUint8Array('network.ezkl');
        const pkData = await fetchAsUint8Array('pk.key');
        const srsData = await fetchAsUint8Array('kzg.srs');

        console.log("Encoding input data...");
        const inputStr = JSON.stringify(inputDataObj);
        const inputDataUint8 = new Uint8ClampedArray(new TextEncoder().encode(inputStr));

        console.log("Generating witness...");
        const witnessBuffer = ezkl.genWitness(networkData, inputDataUint8);
        const witnessData = new Uint8ClampedArray(witnessBuffer);
        console.log("Witness generated (" + witnessData.byteLength + " bytes)");

        console.log("Generating proof... This might take a while and cause OOM!");
        const proofBuffer = ezkl.prove(witnessData, pkData, networkData, srsData);
        console.log("Proof generated (" + proofBuffer.length + " bytes)");
        
        const proofJson = new TextDecoder().decode(proofBuffer);
        const proofObj = JSON.parse(proofJson);
        
        return proofObj;
    } catch(e) {
        console.error("Proof generation failed:", e);
        throw e;
    }
}

// Attach to window for Flutter WebView
if (typeof window !== 'undefined') {
    window.VeilProver = {
        init,
        generateProofFromUrls
    };
    console.log("VeilProver attached to window.");
}

export { init, generateProofFromUrls };
