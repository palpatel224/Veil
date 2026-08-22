import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/github_service.dart';
import '../services/wallet_service.dart';
import '../widgets/reclaim_zktls_dialog.dart';

class DataSourcesScreen extends StatefulWidget {
  const DataSourcesScreen({super.key});

  @override
  State<DataSourcesScreen> createState() => _DataSourcesScreenState();
}

class _DataSourcesScreenState extends State<DataSourcesScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoadingGitHub = false;
  bool _isLoadingWallet = false;
  bool _isLoadingGovt = false;
  String? _githubPrs;
  String? _walletBalance;

  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _walletController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final prs = await _db.getMetric('github_prs');
    final balance = await _db.getMetric('total_balance');
    if (mounted) {
      setState(() {
        _githubPrs = prs;
        _walletBalance = balance;
      });
    }
  }

  @override
  void dispose() {
    _githubController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _connectGitHub() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReclaimZkTlsDialog(
        providerName: "GitHub",
        providerId: "6d3f6753-7ee6-49ee-a545-62f1b1822ae5",
        icon: Icons.code,
        color: const Color(0xFF6E5494),
        onSuccess: (extractedData, sigData) async {
          final username = extractedData['github_username'];
          if (username != null && username.toString().isNotEmpty) {
            try {
              if (mounted) setState(() => _isLoadingGitHub = true);
              final prCount = await GithubService.fetchPullRequestCount(username.toString());
              await _db.updateMetric('github_prs', prCount.toString(), 'github_api');
              if (mounted) {
                _showSuccessSnackbar('GitHub Synced! Verified $username with $prCount PRs.');
                _loadMetrics();
              }
            } catch (e) {
              if (mounted) _showSuccessSnackbar('Failed to fetch PRs for $username.');
            } finally {
              if (mounted) setState(() => _isLoadingGitHub = false);
            }
          } else {
            if (mounted) _showSuccessSnackbar('Failed to extract GitHub username.');
          }
        },
      ),
    );
  }

  void _connectWallet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connect Base Wallet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Enter your Base wallet address (0x...) to sync your on-chain balance to your local enclave.', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _walletController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '0x...',
                hintStyle: const TextStyle(color: AppColors.mutedGrey),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final address = _walletController.text.trim();
                  if (address.isEmpty || !address.startsWith('0x')) return;
                  Navigator.pop(context);
                  setState(() => _isLoadingWallet = true);

                  try {
                    final balances = await WalletService.fetchBalances(address);
                    final ethFormatted = balances['ETH']!.toStringAsFixed(4);
                    final usdcFormatted = balances['USDC']!.toStringAsFixed(4);
                    
                    await _db.updateMetric('eth_balance', ethFormatted, 'sepolia_rpc');
                    await _db.updateMetric('total_balance', usdcFormatted, 'arc_testnet_rpc');
                    // Save the wallet address itself so we know where to send rewards!
                    await _db.updateMetric('recipient_wallet', address, 'user');
                    if (mounted) {
                      _showSuccessSnackbar('Wallet Synced! Balance: $usdcFormatted USDC');
                      _loadMetrics();
                    }
                  } catch (e) {
                    if (mounted) _showSuccessSnackbar('Failed to fetch Wallet balance.');
                  } finally {
                    if (mounted) setState(() => _isLoadingWallet = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Connect & Sync', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _mockUploadAadhaar() async {
    setState(() => _isLoadingGovt = false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Signed XML', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Select your digitally signed Aadhaar XML or e-PAN to store locally. Veil will verify the government signature without revealing your identity.', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoadingGovt = true);
                  await Future.delayed(const Duration(seconds: 2));
                  await _db.updateMetric('age', '24', 'aadhaar_xml');
                  await _db.updateMetric('nationality', 'Indian', 'aadhaar_xml');
                  setState(() => _isLoadingGovt = false);
                  if (mounted) _showSuccessSnackbar('Document Verified & Stored Locally!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Simulate Upload', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sources', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Secure Enclave', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Import data into your local device. This data never leaves your phone, and is only used to generate ZK Proofs locally.', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
            const SizedBox(height: 32),

            _buildIntegrationCard(
              title: 'GitHub (Open API)',
              subtitle: _githubPrs != null ? 'Connected: $_githubPrs PRs' : 'Fetch your merged PRs securely.',
              icon: Icons.code,
              isLoading: _isLoadingGitHub,
              isConnected: _githubPrs != null,
              onTap: _connectGitHub,
              color: const Color(0xFF6E5494),
            ),
            const SizedBox(height: 16),
            _buildIntegrationCard(
              title: 'Base Network',
              subtitle: _walletBalance != null ? 'Connected: $_walletBalance ETH' : 'Sync wallet balance (Sepolia).',
              icon: Icons.account_balance_wallet,
              isLoading: _isLoadingWallet,
              isConnected: _walletBalance != null,
              onTap: _connectWallet,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            _buildIntegrationCard(
              title: 'Govt ID (XML)',
              subtitle: 'Upload digitally signed demographic data.',
              icon: Icons.badge,
              isLoading: _isLoadingGovt,
              isConnected: false,
              onTap: _mockUploadAadhaar,
              color: Colors.orangeAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isLoading,
    required bool isConnected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mutedGrey),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAccent),
                  )
                else if (isConnected)
                  const _PulsingGreenDot()
                else
                  const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 14),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.lock, color: AppColors.primaryAccent.withValues(alpha: 0.8), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Your data never leaves your device. Proofs are generated locally.",
                    style: TextStyle(color: AppColors.primaryAccent.withValues(alpha: 0.8), fontSize: 11),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _PulsingGreenDot extends StatefulWidget {
  const _PulsingGreenDot();

  @override
  State<_PulsingGreenDot> createState() => _PulsingGreenDotState();
}

class _PulsingGreenDotState extends State<_PulsingGreenDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.greenAccent.withValues(alpha: 0.5 + 0.5 * _controller.value),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.2 + 0.3 * _controller.value),
                blurRadius: 8 * _controller.value,
                spreadRadius: 2 * _controller.value,
              )
            ],
          ),
        );
      },
    );
  }
}
