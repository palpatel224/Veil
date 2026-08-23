import railgunEngine from "@railgun-community/engine";
const { RailgunEngine, ShieldNoteERC20, ByteUtils } = railgunEngine;

async function run() {
    const receiver0zkAddress = "0zk1qyqqfwrf7sk7pku3gl0a4ulqydh86nmlmg6ffc7f4vj6cx3t2qaftrv7j6fe3z53la4pw5yrywehw9f8k2qgnj7y2x6hne79julkm907kzaxtq8yml0x5pggnmz";
    const { masterPublicKey, viewingPublicKey } = RailgunEngine.decodeAddress(receiver0zkAddress);
    const random = ByteUtils.randomHex(16);
    const tokenAddress = "0x8cb1ebd2638d984703f47aaf85f7dabecbd1d574";
    const amountStr = "1000000";
    
    try {
        const shield = new ShieldNoteERC20(masterPublicKey, random, BigInt(amountStr), tokenAddress);
        const shieldPrivateKey = "0x" + "0".repeat(64); // dummy
        const shieldRequest = await shield.serialize(ByteUtils.hexToBytes(shieldPrivateKey), viewingPublicKey);
        console.log("Success!");
    } catch (e) {
        console.error("Error:", e);
    }
}
run();
