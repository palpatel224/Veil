import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../widgets/reclaim_zktls_dialog.dart';

class DataSourcesScreen extends StatefulWidget {
  const DataSourcesScreen({super.key});

  @override
  State<DataSourcesScreen> createState() => _DataSourcesScreenState();
}

class _DataSourcesScreenState extends State<DataSourcesScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoadingGitHub = false;
  bool _isLoadingBank = false;
  bool _isLoadingGovt = false;

  void _startReclaimFlow(String provider, String url, IconData icon, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReclaimZkTlsDialog(
        providerName: provider,
        targetUrl: url,
        icon: icon,
        color: color,
        onSuccess: (extractedData, sigData) async {
          // Store extracted features in SQLite
          for (var entry in extractedData.entries) {
            await _db.updateMetric(entry.key, entry.value.toString(), '${provider.toLowerCase()}_zktls');
          }
          
          // Store the cryptographic signature for ZK Proof generation
          await _db.updateMetric('${provider.toLowerCase()}_signature', sigData['signature']!, 'zktls_signature');
          await _db.updateMetric('${provider.toLowerCase()}_hash', sigData['payloadHash']!, 'zktls_hash');

          if (mounted) {
            _showSuccessSnackbar('$provider Connected! Data and ECDSA signature synced securely.');
          }
        },
      ),
    );
  }

  void _mockConnectGitHub() {
    _startReclaimFlow('GitHub', 'https://api.github.com/user', Icons.code, const Color(0xFF6E5494));
  }

  void _mockConnectBank() {
    _startReclaimFlow('Bank API', 'https://api.chase.com/balances', Icons.account_balance, Colors.blueAccent);
  }

  Future<void> _mockUploadAadhaar() async {
    setState(() => _isLoadingGovt = false);
    // Show a bottom sheet to mock file upload
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
                  if (mounted) {
                    _showSuccessSnackbar('Document Verified & Stored Locally!');
                  }
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
              title: 'GitHub (zkTLS)',
              subtitle: 'Fetch your merged PRs securely.',
              icon: Icons.code,
              isLoading: _isLoadingGitHub,
              onTap: _mockConnectGitHub,
              color: const Color(0xFF6E5494),
            ),
            const SizedBox(height: 16),
            _buildIntegrationCard(
              title: 'Bank API (zkTLS)',
              subtitle: 'Sync balance and transaction history.',
              icon: Icons.account_balance,
              isLoading: _isLoadingBank,
              onTap: _mockConnectBank,
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
