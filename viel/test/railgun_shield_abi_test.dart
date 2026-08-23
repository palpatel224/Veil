import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/web3dart.dart';
import 'package:viel/services/railgun_shield_service.dart';

/// Mirrors the claimReward ABI fragment in BlockchainService — kept here so we can
/// verify the ShieldRequest tuple actually encodes without touching the network.
/// If this ABI fragment and the one in blockchain_service.dart ever drift apart,
/// update both together.
const String _claimRewardAbi = '''[
  {
    "name": "claimReward",
    "type": "function",
    "stateMutability": "nonpayable",
    "inputs": [
      { "name": "programId",     "type": "uint256" },
      { "name": "proof",         "type": "bytes"   },
      { "name": "publicInputs",  "type": "uint256[]" },
      { "name": "nullifierHash", "type": "bytes32" },
      { "name": "recipient",     "type": "address" },
      {
        "name": "shieldRequest",
        "type": "tuple",
        "components": [
          {
            "name": "preimage",
            "type": "tuple",
            "components": [
              { "name": "npk", "type": "bytes32" },
              {
                "name": "token",
                "type": "tuple",
                "components": [
                  { "name": "tokenType", "type": "uint8" },
                  { "name": "tokenAddress", "type": "address" },
                  { "name": "tokenSubID", "type": "uint256" }
                ]
              },
              { "name": "value", "type": "uint120" }
            ]
          },
          {
            "name": "ciphertext",
            "type": "tuple",
            "components": [
              { "name": "encryptedBundle", "type": "bytes32[3]" },
              { "name": "shieldKey", "type": "bytes32" }
            ]
          }
        ]
      }
    ],
    "outputs": []
  }
]''';

void main() {
  final contract = DeployedContract(
    ContractAbi.fromJson(_claimRewardAbi, 'PayoutController'),
    EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'),
  );
  final claimFunction = contract.function('claimReward');
  final tokenAddress = EthereumAddress.fromHex(
    '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238',
  );

  test(
    'claimReward ABI parses and encodes with a shielded ERC20 ShieldRequest',
    () {
      final shieldRequest = RailgunShieldService.buildDemoShieldRequest(
        tokenAddress: tokenAddress,
        value: BigInt.from(1000000),
        recipient0zkSeed: '0zk1qexampleaddress',
      );

      final encoded = claimFunction.encodeCall([
        BigInt.one,
        Uint8List(512),
        <BigInt>[BigInt.one, BigInt.two],
        Uint8List(32),
        EthereumAddress.fromHex('0x000000000000000000000000000000000000dEaD'),
        shieldRequest,
      ]);

      expect(encoded.isNotEmpty, isTrue);
      expect(
        encoded.length % 32,
        4,
        reason: 'selector (4 bytes) + 32-byte words',
      );
    },
  );

  test(
    'claimReward ABI parses and encodes with an empty (native-ETH) ShieldRequest',
    () {
      final shieldRequest = RailgunShieldService.emptyShieldRequest();

      final encoded = claimFunction.encodeCall([
        BigInt.one,
        Uint8List(512),
        <BigInt>[BigInt.one, BigInt.two],
        Uint8List(32),
        EthereumAddress.fromHex('0x000000000000000000000000000000000000dEaD'),
        shieldRequest,
      ]);

      expect(encoded.isNotEmpty, isTrue);
    },
  );
}
