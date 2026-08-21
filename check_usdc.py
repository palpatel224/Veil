from web3 import Web3
import json

rpc = "https://ethereum-sepolia-rpc.publicnode.com"
w3 = Web3(Web3.HTTPProvider(rpc))

# Sepolia USDC
usdc_address = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238"
wallet = "0x3e383c569c9A6B7f75328E91529EB35Bf721EFf0"

erc20_abi = [
    {
        "constant": True,
        "inputs": [{"name": "_owner", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"name": "balance", "type": "uint256"}],
        "type": "function",
    }
]

contract = w3.eth.contract(address=w3.to_checksum_address(usdc_address), abi=erc20_abi)
balance = contract.functions.balanceOf(w3.to_checksum_address(wallet)).call()
print(f"USDC Balance: {balance / 10**6}")

# Also check ETH
eth_bal = w3.eth.get_balance(w3.to_checksum_address(wallet))
print(f"ETH Balance: {eth_bal / 10**18}")

