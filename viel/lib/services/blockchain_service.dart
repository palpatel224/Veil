import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'database_service.dart';
import 'proof_service.dart';

/// Result returned after attempting to submit a proof on-chain.
class ClaimResult {
  final bool success;
  final String? txHash;
  final String? explorerUrl;
  final String? error;

  /// True if the reward was shielded into RAILGUN's private pool instead of
  /// being sent as a plain public transfer to [recipientAddress].
  final bool isShielded;

  const ClaimResult({
    required this.success,
    this.txHash,
    this.explorerUrl,
    this.error,
    this.isShielded = false,
  });
}

/// Connects the Flutter ZK proof to the live Veil PayoutController contract
/// deployed on Ethereum Sepolia testnet.
///
/// Contract addresses (Ethereum Sepolia, Chain ID 11155111):
///   Halo2Verifier     : 0x369005861e0E5E19229ED6D234C60750F159e241
///   NullifierRegistry : 0x523030E89291C95cD8F7743f4C4B1433ff5383a6
///   PayoutController  : 0x54b76c42BF69FA5b62637A4d0E5f9B46A58AE6c0
class BlockchainService {
  static final EthereumAddress _zeroAddress = EthereumAddress.fromHex(
    '0x0000000000000000000000000000000000000000',
  );

  // ── Network Config ──────────────────────────────────────────────────────────
  static String _getRpcUrl(int programId) {
    if (programId == 101) return 'https://rpc.testnet.arc.network';
    return 'https://ethereum-sepolia-rpc.publicnode.com';
  }

  static String _getExplorerBase(int programId) {
    if (programId == 101)
      return 'https://testnet.arcanescan.com/tx'; // Adjust as needed
    return 'https://sepolia.etherscan.io/tx';
  }

  static int _getChainId(int programId) {
    if (programId == 101) return 5042002;
    return 11155111;
  }

  // ── Deployed Contract Addresses ─────────────────────────────────────────────
  static EthereumAddress _getPayoutControllerAddress(int programId) {
    if (programId == 101) {
      return EthereumAddress.fromHex(
        '0xB012655ba9cb837B93B70Adea3BCDfE488e11571',
      ); // ARC Testnet
    }
    return EthereumAddress.fromHex(
      '0x9d42102FC751caF76F611f62Dd2e34f1d5C266Bd',
    ); // Sepolia
  }

  // ── PayoutController ABI ─────────────────────────────────────────────────────
  // Minimal ABI: only the functions we call from the app.
  static const String _payoutControllerAbi = '''[
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
    },
    {
      "name": "getProgram",
      "type": "function",
      "stateMutability": "view",
      "inputs": [
        { "name": "programId", "type": "uint256" }
      ],
      "outputs": [
        { "name": "name",      "type": "string"  },
        { "name": "rewardWei", "type": "uint256" }
      ]
    },
    {
      "name": "programTokens",
      "type": "function",
      "stateMutability": "view",
      "inputs": [ { "name": "", "type": "uint256" } ],
      "outputs": [ { "name": "", "type": "address" } ]
    },
    {
      "name": "railgun",
      "type": "function",
      "stateMutability": "view",
      "inputs": [],
      "outputs": [ { "name": "", "type": "address" } ]
    }
  ]''';

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Submits the ZK proof to the PayoutController contract.
  ///
  /// [programId]    Matches the on-chain program ID (1, 2, 3, or 4).
  /// [proofHex]     512-byte hex proof from ProofService.dart.
  /// [publicInputs] List of 2 hex strings from ProofService._computePublicInputs().
  /// [userSecret]   A locally stored secret seed for nullifier derivation.
  ///                In production, generate once and store in flutter_secure_storage.
  /// [recipientAddress] The wallet address that should receive the ETH reward.
  /// [privateKeyHex]    The deployer/user private key that signs the transaction.
  ///                    In production, use WalletConnect instead of raw key.
  static Future<ClaimResult> submitProof({
    required int programId,
    required String proofHex,
    required List<String> publicInputs,
    required String userSecret,
    required String recipientAddress,
    required String privateKeyHex,
    Function(String)? onStatus,
  }) async {
    try {
      final rpcUrl = _getRpcUrl(programId);
      final chainId = _getChainId(programId);
      final explorerBase = _getExplorerBase(programId);
      final payoutControllerAddress = _getPayoutControllerAddress(programId);

      if (onStatus != null) onStatus('Connecting to Network...');

      final client = Web3Client(rpcUrl, http.Client());
      final credentials = EthPrivateKey.fromHex(privateKeyHex);

      // 1. Decode proof from hex string → raw bytes
      if (onStatus != null) onStatus('Encoding proof for contract...');
      final proofBytes = _hexToBytes(proofHex);

      // 2. Convert publicInputs (hex strings) → BigInt for Solidity uint256[]
      final publicInputsBigInt = publicInputs
          .map((hex) => BigInt.parse(hex, radix: 16))
          .toList();

      // 3. Compute nullifier: SHA256(user_secret + program_id)
      //    This is deterministic — same user + same program always gives the same nullifier.
      //    The contract uses this to prevent double-claiming.
      if (onStatus != null) onStatus('Computing nullifier hash...');
      final nullifierHash = _computeNullifier(userSecret, programId);

      // 4. Load the contract
      final contract = DeployedContract(
        ContractAbi.fromJson(_payoutControllerAbi, 'PayoutController'),
        payoutControllerAddress,
      );
      final claimFunction = contract.function('claimReward');

      // 5. Look up whether this program pays out in ERC20 (shielded via RAILGUN)
      //    or native ETH/ARC (plain transfer) — see PayoutController._executePayout().
      if (onStatus != null) onStatus('Checking program payout type...');
      final tokenResult = await client.call(
        contract: contract,
        function: contract.function('programTokens'),
        params: [BigInt.from(programId)],
      );
      final programToken = tokenResult[0] as EthereumAddress;
      final isShielded = programToken != _zeroAddress;

      // For on-chain verification, recipient must be EthereumAddress
      // If shielded, the actual recipient is encoded in the ShieldRequest, and the smart contract ignores this field.
      final recipient = isShielded 
          ? EthereumAddress.fromHex('0x0000000000000000000000000000000000000000') 
          : EthereumAddress.fromHex(recipientAddress);
      List<dynamic> shieldRequest;
      if (isShielded) {
        if (onStatus != null) onStatus('Preparing shielded RAILGUN note...');
        final programResult = await client.call(
          contract: contract,
          function: contract.function('getProgram'),
          params: [BigInt.from(programId)],
        );
        final rewardWei = programResult[1] as BigInt;
        
        final req = await ProofService.buildRailgunShieldRequest(
          programToken.hex,
          rewardWei,
          recipientAddress,
        );
        if (req == null) throw Exception("Failed to build Railgun Shield Request");
        shieldRequest = req;
      } else {
        shieldRequest = ProofService.emptyShieldRequest();
      }

      // 6. Send the transaction
      if (onStatus != null) {
        onStatus(
          isShielded
              ? 'Shielding reward into RAILGUN privacy pool...'
              : 'Submitting to blockchain...',
        );
      }
      final txHash = await client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: claimFunction,
          parameters: [
            BigInt.from(programId),
            proofBytes,
            publicInputsBigInt,
            nullifierHash,
            recipient,
            shieldRequest,
          ],
          maxGas: 800000,
        ),
        chainId: chainId,
      );

      if (onStatus != null)
        onStatus('Transaction submitted! Waiting for confirmation...');

      // Poll for receipt
      TransactionReceipt? receipt;
      int attempts = 0;
      while (receipt == null && attempts < 30) {
        await Future.delayed(const Duration(seconds: 2));
        receipt = await client.getTransactionReceipt(txHash);
        attempts++;
      }

      await client.dispose();

      if (receipt != null && receipt.status == false) {
        return ClaimResult(
          success: false,
          txHash: txHash,
          explorerUrl: '$explorerBase/$txHash',
          error:
              'Transaction failed on-chain (reverted). Check Etherscan for details.',
        );
      } else if (receipt == null) {
        return ClaimResult(
          success: false,
          txHash: txHash,
          explorerUrl: '$explorerBase/$txHash',
          error: 'Transaction confirmation timed out. It might still succeed.',
        );
      }

      final dateStr =
          '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}';
      String amountStr = '+0.001 sETH';
      String title = 'Proof Verified';
      String subtitle = 'Verified Program';
      if (programId == 4) subtitle = 'USDC Tester Grant';
      if (programId == 5) subtitle = 'blocsoc grants';
      if (programId == 101) subtitle = 'ARC Testnet Grant';
      if (programId == 6) subtitle = 'ETH Hacker Grant';
      if (programId == 7) subtitle = 'USDC Power User';
      if (programId == 9 || programId == 11) subtitle = 'Starter Grant';

      if (programId == 4) amountStr = '+5.00 USDC';
      if (programId == 5) amountStr = '+0.001 SETH';
      if (programId == 101) amountStr = '+1.00 ARC';
      if (programId == 6) amountStr = '+0.001 ETH';
      if (programId == 7) amountStr = '+2.00 USDC';
      if (programId == 9 || programId == 11) amountStr = '+15.00 USDC';

      try {
        await DatabaseService().addTransaction(
          title,
          subtitle,
          amountStr,
          dateStr,
          txHash,
          0,
        );
      } catch (e) {
        // ignore DB error
      }

      return ClaimResult(
        success: true,
        txHash: txHash,
        explorerUrl: '$explorerBase/$txHash',
        isShielded: isShielded,
      );
    } catch (e) {
      return ClaimResult(success: false, error: _parseError(e.toString()));
    }
  }

  /// Reads program name and reward from the contract (no gas needed — read-only).
  static Future<Map<String, dynamic>?> getProgramInfo(int programId) async {
    try {
      final rpcUrl = _getRpcUrl(programId);
      final payoutControllerAddress = _getPayoutControllerAddress(programId);

      final client = Web3Client(rpcUrl, http.Client());
      final contract = DeployedContract(
        ContractAbi.fromJson(_payoutControllerAbi, 'PayoutController'),
        payoutControllerAddress,
      );

      final result = await client.call(
        contract: contract,
        function: contract.function('getProgram'),
        params: [BigInt.from(programId)],
      );

      await client.dispose();

      final rewardWei = result[1] as BigInt;
      final rewardEth = rewardWei.toDouble() / 1e18;

      return {
        'name': result[0] as String,
        'rewardEth': rewardEth,
        'rewardWei': rewardWei.toString(),
      };
    } catch (_) {
      return null;
    }
  }

  /// Verification helper: reads the RAILGUN pool address wired into
  /// PayoutController via setRailgunSmartWallet(). Returns null on read failure,
  /// or the zero address if the owner hasn't wired it up yet.
  static Future<String?> getRailgunPoolAddress(int programId) async {
    try {
      final rpcUrl = _getRpcUrl(programId);
      final payoutControllerAddress = _getPayoutControllerAddress(programId);

      final client = Web3Client(rpcUrl, http.Client());
      final contract = DeployedContract(
        ContractAbi.fromJson(_payoutControllerAbi, 'PayoutController'),
        payoutControllerAddress,
      );

      final result = await client.call(
        contract: contract,
        function: contract.function('railgun'),
        params: [],
      );

      await client.dispose();

      return (result[0] as EthereumAddress).hex;
    } catch (_) {
      return null;
    }
  }

  // ── Private Helpers ──────────────────────────────────────────────────────────

  /// Converts a hex proof string to raw bytes for ABI encoding.
  static Uint8List _hexToBytes(String hex) {
    final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
    final bytes = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  /// Derives a 32-byte nullifier: SHA256(user_secret + program_id).
  /// Matches the pattern expected by NullifierRegistry.sol.
  static Uint8List _computeNullifier(String userSecret, int programId) {
    final input = utf8.encode('$userSecret:$programId');
    final digest = sha256.convert(input);
    return Uint8List.fromList(digest.bytes);
  }

  /// Extracts a human-readable error message from web3dart exceptions.
  static String _parseError(String raw) {
    if (raw.contains('AlreadyClaimed')) {
      return 'You have already claimed this program reward.';
    }
    if (raw.contains('NoRewardForProgram')) {
      return 'This program has no remaining rewards.';
    }
    if (raw.contains('InvalidProof')) {
      return 'Proof verification failed on-chain.';
    }
    if (raw.contains('RailgunNotConfigured')) {
      return 'This program pays out via RAILGUN, but the pool isn\'t wired up yet.';
    }
    if (raw.contains('ShieldRequestMismatch')) {
      return 'Shielded note did not match the program\'s token/amount.';
    }
    if (raw.contains('insufficient funds')) {
      return 'Wallet has insufficient ETH for gas fees.';
    }
    return 'Transaction failed: $raw';
  }
}
