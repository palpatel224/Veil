"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.initRailgun = initRailgun;
exports.createWallet = createWallet;
const wallet_1 = require("@railgun-community/wallet");
const shared_models_1 = require("@railgun-community/shared-models");
// Simple in-memory leveldown substitute for the browser
const leveljs = require('level-js');
let wallet = null;
async function initRailgun() {
    try {
        // 1. Initialize Railgun Engine
        // The engine requires a LevelDOWN compatible database. 
        // For browser/webview, we use level-js (IndexedDB wrapper).
        const db = leveljs('railgun-db');
        (0, wallet_1.startRailgunEngine)("veil-railgun", db, true, // shouldDebug
        {
            getArtifactsUrl: () => 'https://railgun-artifacts.s3.amazonaws.com'
        }, // artifact store
        false, // useNativeArtifacts
        true);
        // 2. Load Provider (Sepolia)
        const RPC_URL = "https://ethereum-sepolia-rpc.publicnode.com";
        const fallbackProviders = {
            [shared_models_1.NetworkName.EthereumSepolia]: [RPC_URL]
        };
        await (0, wallet_1.loadProvider)({
            providers: fallbackProviders
        }, shared_models_1.NetworkName.EthereumSepolia);
        return { success: true };
    }
    catch (error) {
        return { success: false, error: error.message };
    }
}
async function createWallet(encryptionKey, mnemonic) {
    try {
        const railgunWalletInfo = await (0, wallet_1.createRailgunWallet)(encryptionKey, mnemonic, undefined);
        wallet = railgunWalletInfo;
        // Generate a 0zk address
        const address = railgunWalletInfo.railgunAddress || railgunWalletInfo.id;
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
