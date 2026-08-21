import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import 'data_sources_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _totalBalance = '0.00';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final balance = await DatabaseService().getMetric('total_balance');
    if (mounted) {
      setState(() {
        _totalBalance = balance ?? '0.00';
        _isLoading = false;
      });
    }
  }

  void _showDummySnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.mutedGrey),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 24),
              const Text(
                'Disconnect Wallet?',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to disconnect your wallet? You will need to reconnect to generate proofs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.mutedGrey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDummySnackbar(context, 'Wallet disconnected (Mock).');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Disconnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 32, backgroundColor: AppColors.primaryAccent, child: Icon(Icons.person, size: 32, color: Colors.white)),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alex Doe', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('0x71...E8F4', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Verified', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 40),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.mutedGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('Private Balance', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                      Spacer(),
                      Icon(Icons.shield_outlined, color: AppColors.primaryAccent, size: 16),
                      SizedBox(width: 4),
                      Text('Shielded', style: TextStyle(color: AppColors.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoading 
                      ? const CircularProgressIndicator(color: AppColors.primaryAccent)
                      : Text('$_totalBalance ETH', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showDummySnackbar(context, 'Receive features coming in Phase X'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedGrey, foregroundColor: Colors.white),
                          child: const Text('Receive'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showDummySnackbar(context, 'Send features coming in Phase X'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: Colors.white),
                          child: const Text('Send'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            _buildSectionHeader('Wallet'),
            _buildListTile(context, Icons.account_balance_wallet_outlined, 'Balance', () => _showDummySnackbar(context, 'Balance details coming soon')),
            _buildListTile(context, Icons.history, 'Transaction history', () => _showDummySnackbar(context, 'Transaction history coming soon')),
            
            const SizedBox(height: 24),
            _buildSectionHeader('My Activity'),
            _buildListTile(context, Icons.verified_outlined, 'Claims', () => _showDummySnackbar(context, 'Claims coming soon')),
            _buildListTile(context, Icons.file_copy_outlined, 'Proofs', () => _showDummySnackbar(context, 'Proofs coming soon')),
            _buildListTile(context, Icons.card_giftcard, 'Rewards received', () => _showDummySnackbar(context, 'Rewards coming soon')),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Private Data'),
            _buildListTile(
              context, 
              Icons.sync_alt, 
              'Data Sources', 
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DataSourcesScreen()),
              ),
            ),
            _buildListTile(context, Icons.sd_storage_outlined, 'Local storage', () => _showDummySnackbar(context, 'Local storage coming in Phase 2')),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Settings'),
            _buildListTile(context, Icons.security, 'Security & Privacy', () => _showDummySnackbar(context, 'Security settings coming soon')),
            _buildListTile(context, Icons.palette_outlined, 'Appearance', () => _showDummySnackbar(context, 'Appearance settings coming soon')),
            _buildListTile(context, Icons.help_outline, 'Help & Support', () => _showDummySnackbar(context, 'Help desk coming soon')),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showDisconnectDialog(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Disconnect Wallet', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(title, style: const TextStyle(color: AppColors.primaryAccent, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.mutedGrey)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 12),
      onTap: onTap,
    );
  }
}
