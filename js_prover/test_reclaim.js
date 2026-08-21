import reclaimSdk from '@reclaimprotocol/js-sdk';
const { ReclaimProofRequest } = reclaimSdk;

const appId = "0xA3e396d039f7D02D03719F8c19a3B509403b06C2";
const appSecret = "0x9cc298d5c968984bb22d7848bf46d8e85c35b86a43bd6b69f31380d33e96ec2e";
const providerId = "6d3f6753-7ee6-49ee-a545-62f1b1822ae5";

async function main() {
    try {
        console.log("Initializing...");
        const req = await ReclaimProofRequest.init(appId, appSecret, providerId);
        const url = await req.getRequestUrl();
        console.log("URL:", url);
    } catch (e) {
        console.error("Error:", e);
    }
}
main();
