import { startRailgunEngine, createRailgunWallet, NetworkName, loadProvider } from '@railgun-community/wallet';
// Simple in-memory leveldown substitute for the browser
const leveljs = require('level-js');
let wallet = null;
export async function initRailgun() {
    try {
        // 1. Initialize Railgun Engine
        // The engine requires a LevelDOWN compatible database. 
        // For browser/webview, we use level-js (IndexedDB wrapper).
        const db = leveljs('railgun-db');
        startRailgunEngine("veil-railgun", db, true, // shouldDebug
        {
            getArtifactsUrl: () => 'https://railgun-artifacts.s3.amazonaws.com'
        }, // artifact store
        false, // useNativeArtifacts
        true);
        // 2. Load Provider (Sepolia)
        const RPC_URL = "https://ethereum-sepolia-rpc.publicnode.com";
        const fallbackProviders = {
            [NetworkName.EthereumSepolia]: [RPC_URL]
        };
        await loadProvider({
            networkName: NetworkName.EthereumSepolia,
            providers: fallbackProviders
        }, NetworkName.EthereumSepolia);
        return { success: true };
    }
    catch (error) {
        return { success: false, error: error.message };
    }
}
export async function createWallet(encryptionKey, mnemonic) {
    try {
        const railgunWalletInfo = await createRailgunWallet(encryptionKey, mnemonic, undefined);
        wallet = railgunWalletInfo;
        // Generate a 0zk address
        const address = railgunWalletInfo.railgunWalletInfo.railgunAddress;
        return { success: true, address: address, id: railgunWalletInfo.id };
    }
    catch (error) {
        return { success: false, error: error.message };
    }
}
// Attach to window for Flutter WebView to call
window.VeilRailgun = {
    initRailgun,
    createWallet
};
