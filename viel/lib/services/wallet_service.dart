import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class WalletService {
  // Free public RPC for Ethereum Sepolia
  static const String rpcUrl = 'https://ethereum-sepolia-rpc.publicnode.com';
  
  static Future<double> fetchBalance(String walletAddress) async {
    try {
      final client = Web3Client(rpcUrl, http.Client());
      final address = EthereumAddress.fromHex(walletAddress);
      
      final balance = await client.getBalance(address);
      
      // Convert Wei (BigInt) to ETH (double)
      // Wei is 10^18
      final ethBalance = balance.getInWei.toDouble() / math.pow(10, 18);
      
      await client.dispose();
      return ethBalance;
    } catch (e) {
      throw Exception('Failed to fetch wallet balance: $e');
    }
  }
}
