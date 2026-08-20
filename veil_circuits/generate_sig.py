import os
import hashlib
from ecdsa import SigningKey, SECP256k1
from ecdsa.util import sigencode_string

# 1. Generate a mock Trusted Attester private/public keypair
sk = SigningKey.generate(curve=SECP256k1)
vk = sk.verifying_key

pub_key_bytes = vk.to_string()
pub_key_x = pub_key_bytes[:32]
pub_key_y = pub_key_bytes[32:]

# 2. Create a mock payload hash (e.g., hash of "user_balance=10000;user_prs=3")
message = b"user_balance=10000;user_prs=3"
message_hash = hashlib.sha256(message).digest()

# 3. Sign the message hash
signature = sk.sign_digest_deterministic(message_hash, hashfunc=hashlib.sha256, sigencode=sigencode_string)

# 4. Format arrays for Noir TOML (as an array of strings representing hex/ints)
def to_toml_array(byte_array):
    return "[" + ", ".join([f'"{b}"' for b in byte_array]) + "]"

toml_content = f"""min_balance = "5000"
min_prs = "1"
user_balance = "10000"
user_prs = "3"

attester_pub_key_x = {to_toml_array(pub_key_x)}
attester_pub_key_y = {to_toml_array(pub_key_y)}
signature = {to_toml_array(signature)}
message_hash = {to_toml_array(message_hash)}
"""

with open("Prover.toml", "w") as f:
    f.write(toml_content)

print("Generated Prover.toml with valid ECDSA signature!")
