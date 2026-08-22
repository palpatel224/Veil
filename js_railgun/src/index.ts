import { startRailgunEngine, createRailgunWallet, loadProvider } from '@railgun-community/wallet';
import { NetworkName } from '@railgun-community/shared-models';

// Simple in-memory leveldown substitute for the browser
const leveljs = require('level-js');

let wallet: any = null;

export async function initRailgun() {
  try {
    // 1. Initialize Railgun Engine
    // The engine requires a LevelDOWN compatible database. 
    // For browser/webview, we use level-js (IndexedDB wrapper).
    const db = leveljs('railgun-db');
    
    startRailgunEngine(
      "veil-railgun",
      db,
      true, // shouldDebug
      {
        getArtifactsUrl: () => 'https://railgun-artifacts.s3.amazonaws.com'
      } as any, // artifact store
      false, // useNativeArtifacts
      true, // skipMerkletreeSync
    );

    // 2. Load Provider (Sepolia)
    const RPC_URL = "https://ethereum-sepolia-rpc.publicnode.com";
    const fallbackProviders = {
      [NetworkName.EthereumSepolia]: [RPC_URL]
    };
    await loadProvider({
      providers: fallbackProviders
    } as any, NetworkName.EthereumSepolia);

    return { success: true };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

export async function createWallet(encryptionKey: string, mnemonic: string) {
  try {
    const railgunWalletInfo = await createRailgunWallet(encryptionKey, mnemonic, undefined);
    wallet = railgunWalletInfo;
    
    // Generate a 0zk address
    const address = (railgunWalletInfo as any).railgunAddress || (railgunWalletInfo as any).id;
    
    return { success: true, address: address, id: railgunWalletInfo.id };
  } catch (error: any) {
    return { success: false, error: error.message };
  }
}

// Attach to window for Flutter WebView to call
(window as any).VeilRailgun = {
  initRailgun,
  createWallet
};
