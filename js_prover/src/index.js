import initWasm, * as ezkl from '@ezkljs/engine';
import { createRailgunPlugin, RailgunAddress } from '@kohaku-eth/railgun';
import { viem as viemProvider } from '@kohaku-eth/provider/viem';
import { createPublicClient, http, decodeFunctionData } from 'viem';
import { sepolia } from 'viem/chains';
import reclaimSdk from '@reclaimprotocol/js-sdk';

class MemoryStorage {
  constructor() { this.map = new Map(); }
  async set(key, value) { this.map.set(key, value); }
  async get(key) { return this.map.get(key) ?? null; }
}

class DummyKeystore {
  async deriveAt(path) { return '0x' + '0'.repeat(64); }
}

let pluginInstance = null;

async function initRailgun() {
    if (pluginInstance) return;
    const publicClient = createPublicClient({
      chain: sepolia,
      transport: http('https://ethereum-sepolia-rpc.publicnode.com'),
    });
    const host = {
      network: { fetch: (input, init) => globalThis.fetch(input, init) },
      storage: new MemoryStorage(),
      keystore: new DummyKeystore(),
      provider: viemProvider(publicClient),
    };
    pluginInstance = await createRailgunPlugin(host, { logLevel: 'Off', poi: false });
}

async function init() {
    console.log("Initializing EZKL...");
    await initWasm();
    if (!ezkl || !ezkl.prove) {
        throw new Error("Failed to load EZKL engine!");
    }
    console.log("EZKL Engine loaded successfully.");
}

async function fetchAsUint8Array(url) {
    const response = await fetch(url);
    if (!response.ok) throw new Error("Failed to fetch " + url + ": " + response.statusText);
    const buffer = await response.arrayBuffer();
    return new Uint8ClampedArray(buffer);
}

async function generateProofFromUrls(inputDataObj) {
    try {
        const networkData = await fetchAsUint8Array('network.ezkl');
        const pkData = await fetchAsUint8Array('pk.key');
        const srsData = await fetchAsUint8Array('kzg.srs');

        const inputStr = JSON.stringify(inputDataObj);
        const inputDataUint8 = new Uint8ClampedArray(new TextEncoder().encode(inputStr));

        const witnessBuffer = ezkl.genWitness(networkData, inputDataUint8);
        const witnessData = new Uint8ClampedArray(witnessBuffer);

        const proofBuffer = ezkl.prove(witnessData, pkData, networkData, srsData);
        
        const proofJson = new TextDecoder().decode(proofBuffer);
        return JSON.parse(proofJson);
    } catch(e) {
        console.error("Proof generation failed:", e);
        throw e;
    }
}

const { ReclaimProofRequest } = reclaimSdk;
let currentReclaimRequest = null;

async function buildReclaimRequest(providerId, appId, appSecret) {
    try {
        currentReclaimRequest = await ReclaimProofRequest.init(appId, appSecret, providerId);
        const requestUrl = await currentReclaimRequest.getRequestUrl();
        return JSON.stringify({ success: true, requestUrl: requestUrl });
    } catch(e) {
        return JSON.stringify({ success: false, error: e.toString() });
    }
}

async function startReclaimSession() {
    return new Promise((resolve) => {
        if (!currentReclaimRequest) {
            resolve(JSON.stringify({ success: false, error: "No client initialized" }));
            return;
        }
        currentReclaimRequest.startSession({
            onSuccess: proof => resolve(JSON.stringify({ success: true, proof: proof })),
            onError: error => resolve(JSON.stringify({ success: false, error: error.toString() }))
        });
    });
}

const railgunAbi = [{
  name: 'shield',
  type: 'function',
  inputs: [{
    name: '_shieldRequests',
    type: 'tuple[]',
    components: [
      {
        name: 'preimage',
        type: 'tuple',
        components: [
          { name: 'npk', type: 'bytes32' },
          {
            name: 'token',
            type: 'tuple',
            components: [
              { name: 'tokenType', type: 'uint8' },
              { name: 'tokenAddress', type: 'address' },
              { name: 'tokenSubID', type: 'uint256' }
            ]
          },
          { name: 'value', type: 'uint120' }
        ]
      },
      {
        name: 'ciphertext',
        type: 'tuple',
        components: [
          { name: 'encryptedBundle', type: 'bytes32[3]' },
          { name: 'shieldKey', type: 'bytes32' }
        ]
      }
    ]
  }]
}];

async function buildRailgunShieldRequest(tokenAddress, amountStr, receiver0zkAddress) {
    try {
        await initRailgun();
        
        let builder = pluginInstance.provider.shield();
        
        console.log('buildRailgunShieldRequest step 3: builder.shield()');
        builder = builder.shield(receiver0zkAddress, { type: "Erc20", value: tokenAddress }, BigInt(amountStr));
        
        console.log('buildRailgunShieldRequest step 4: builder.build()');
        const txs = builder.build();
        
        if (txs.length === 0) throw new Error("No transactions generated");
        
        const decoded = decodeFunctionData({ abi: railgunAbi, data: txs[0].data });
        const req = decoded.args[0][0]; // First ShieldRequest in array
        
        const shieldRequest = [
            [
                req.preimage.npk,
                [
                    Number(req.preimage.token.tokenType),
                    req.preimage.token.tokenAddress,
                    req.preimage.token.tokenSubID.toString()
                ],
                req.preimage.value.toString()
            ],
            [
                req.ciphertext.encryptedBundle,
                req.ciphertext.shieldKey
            ]
        ];
        
        return JSON.stringify({ success: true, shieldRequest });
    } catch (e) {
        console.error('buildRailgunShieldRequest error details:', e);
        if (e.stack) console.error('Stack trace:', e.stack);
        return JSON.stringify({ success: false, error: e.message || e.toString() });
    }
}

if (typeof window !== 'undefined') {
    window.VeilProver = {
        init,
        generateProofFromUrls,
        buildReclaimRequest,
        startReclaimSession,
        buildRailgunShieldRequest
    };
}

export { init, generateProofFromUrls, buildReclaimRequest, startReclaimSession, buildRailgunShieldRequest };
