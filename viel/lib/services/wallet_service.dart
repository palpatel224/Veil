import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class WalletService {
  static Future<Map<String, double>> fetchBalances(String walletAddress) async {
    try {
      final sepClient = Web3Client('https://ethereum-sepolia-rpc.publicnode.com', http.Client());
      final arcClient = Web3Client('https://rpc.testnet.arc.network', http.Client());
      
      final address = EthereumAddress.fromHex(walletAddress);
      
      final sepBalance = await sepClient.getBalance(address);
      final arcBalance = await arcClient.getBalance(address);
      
      // Convert Wei (BigInt) to Token (double) - both use 18 decimals
      final sepEth = sepBalance.getInWei.toDouble() / math.pow(10, 18);
      final arcUsdc = arcBalance.getInWei.toDouble() / math.pow(10, 18);
      
      // Fetch MockUSDC on Sepolia
      final usdcContract = DeployedContract(
        ContractAbi.fromJson('[{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]', 'MockUSDC'),
        EthereumAddress.fromHex('0xfA3E6924BB0C5494075D35338F7e02Dc22897cb6'),
      );
      final usdcBalanceRaw = await sepClient.call(contract: usdcContract, function: usdcContract.function('balanceOf'), params: [address]);
      final sepoliaUsdc = (usdcBalanceRaw.first as BigInt).toDouble() / math.pow(10, 6);
      
      await sepClient.dispose();
      await arcClient.dispose();
      
      return {
        'ETH': sepEth,
        'USDC': arcUsdc + sepoliaUsdc,
      };
    } catch (e) {
      throw Exception('Failed to fetch wallet balances: $e');
    }
  }
}
