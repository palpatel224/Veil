import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/github_service.dart';
import '../services/wallet_service.dart';

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

  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _walletController = TextEditingController();

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
            const Text('Connect GitHub', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Enter your GitHub username to securely fetch your public PR stats into your local enclave.', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _githubController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Username',
                hintStyle: const TextStyle(color: AppColors.mutedGrey),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.code, color: Color(0xFF6E5494)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final username = _githubController.text.trim();
                  if (username.isEmpty) return;
                  Navigator.pop(context);
                  setState(() => _isLoadingGitHub = true);

                  try {
                    final prCount = await GithubService.fetchPullRequestCount(username);
                    await _db.updateMetric('github_prs', prCount.toString(), 'github_api');
                    if (mounted) _showSuccessSnackbar('GitHub Synced! Found $prCount PRs.');
                  } catch (e) {
                    if (mounted) _showSuccessSnackbar('Failed to fetch GitHub data.');
                  } finally {
                    if (mounted) setState(() => _isLoadingGitHub = false);
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
                    final balance = await WalletService.fetchBalance(address);
                    final formattedBalance = balance.toStringAsFixed(4);
                    await _db.updateMetric('total_balance', formattedBalance, 'base_sepolia_rpc');
                    // Save the wallet address itself so we know where to send rewards!
                    await _db.updateMetric('recipient_wallet', address, 'user');
                    if (mounted) _showSuccessSnackbar('Wallet Synced! Balance: $formattedBalance ETH');
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
              subtitle: 'Fetch your merged PRs securely.',
              icon: Icons.code,
              isLoading: _isLoadingGitHub,
              onTap: _connectGitHub,
              color: const Color(0xFF6E5494),
            ),
            const SizedBox(height: 16),
            _buildIntegrationCard(
              title: 'Base Network',
              subtitle: 'Sync wallet balance (Sepolia).',
              icon: Icons.account_balance_wallet,
              isLoading: _isLoadingWallet,
              onTap: _connectWallet,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            _buildIntegrationCard(
              title: 'Govt ID (XML)',
              subtitle: 'Upload digitally signed demographic data.',
              icon: Icons.badge,
              isLoading: _isLoadingGovt,
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
        child: Row(
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
            else
              const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 14),
          ],
        ),
      ),
    );
  }
}
