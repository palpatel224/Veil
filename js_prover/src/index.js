const { Noir } = require('@noir-lang/noir_js');
const { BarretenbergBackend } = require('@noir-lang/backend_barretenberg');
const circuit = require('./circuit.json');

let noir = null;
let backend = null;

async function init() {
  if (!backend) {
    backend = new BarretenbergBackend(circuit);
    noir = new Noir(circuit, backend);
    await noir.init();
  }
  return true;
}

async function generateProof(inputs) {
  try {
    await init();
    const proof = await noir.generateFinalProof(inputs);
    return {
      success: true,
      proof: Buffer.from(proof.proof).toString('hex'),
      publicInputs: proof.publicInputs.map(x => Buffer.from(x).toString('hex'))
    };
  } catch (e) {
    return { success: false, error: e.toString() };
  }
}

module.exports = { init, generateProof };
