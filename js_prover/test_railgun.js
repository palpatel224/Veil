import { createRailgunPlugin } from '@kohaku-eth/railgun';
import { viem as viemProvider } from '@kohaku-eth/provider/viem';
import { createPublicClient, http, decodeFunctionData } from 'viem';
import { sepolia } from 'viem/chains';

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

async function run() {
  try {
    await initRailgun();
    console.log("Initialized");
    
    const receiver0zkAddress = "0zk1qyqqfwrf7sk7pku3gl0a4ulqydh86nmlmg6ffc7f4vj6cx3t2qaftrv7j6fe3z53la4pw5yrywehw9f8k2qgnj7y2x6hne79julkm907kzaxtq8yml0x5pggnmz";
    const tokenAddress = "0x8cB1EBd2638d984703F47aaf85f7DAbecbd1D574";
    const amountStr = "5000000";
    
    const builder = pluginInstance.provider.shield();
    builder.shield(receiver0zkAddress, { type: "Erc20", value: tokenAddress }, BigInt(amountStr));
    const txs = builder.build();
    
    console.log("Tx to:", txs[0].to);
    console.log("Tx data length:", txs[0].data.length);
    
    const decoded = decodeFunctionData({ abi: railgunAbi, data: txs[0].data });
    const req = decoded.args[0][0];
    
    console.log("Decoded preimage npk:", req.preimage.npk);
    console.log("Decoded amount:", req.preimage.value.toString());
  } catch(e) {
    console.error(e);
  }
}
run();
