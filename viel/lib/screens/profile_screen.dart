import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import 'data_sources_screen.dart';
import 'transaction_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _totalBalance = '0.00';
  String _walletAddress = '0x...';
  String _githubPrs = '0';
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final db = DatabaseService();
    final balance = await db.getMetric('total_balance');
    final address = await db.getMetric('recipient_wallet');

    final prs = await db.getMetric('github_prs');
    
    if (mounted) {
      setState(() {
        _totalBalance = balance ?? '0.00';
        _walletAddress = (address != null && address.length > 10) 
            ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}' 
            : '0x...';
        _githubPrs = prs ?? '0';
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
        margin: const EdgeInsets.only(bottom: 112, left: 24, right: 24),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        final db = DatabaseService();
                        await db.deleteMetric('recipient_wallet');
                        await db.deleteMetric('total_balance');
                        await db.deleteMetric('eth_balance');
                        await db.deleteMetric('arc_balance');
                        await db.clearAllTransactions();
                        await _loadMetrics();
                        if (!context.mounted) return;
                        _showDummySnackbar(context, 'Wallet disconnected successfully');
                      },
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
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
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
                    const Text('Anon User', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_walletAddress, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('ZK Verified', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
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
                          onPressed: () => _showReceiveModal(context),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedGrey, foregroundColor: Colors.white),
                          child: const Text('Receive'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showSendModal(context),
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
            _buildListTile(context, Icons.account_balance_wallet_outlined, 'Balance', () => _showDummySnackbar(context, 'Total Shielded: \$$_totalBalance USDC')),
            _buildListTile(context, Icons.history, 'Transaction history', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()))),
            
            const SizedBox(height: 24),
            _buildSectionHeader('My Activity'),
            _buildListTile(context, Icons.verified_outlined, 'Claims', () => _showDummySnackbar(context, '$_githubPrs GitHub PR claims verified')),
            _buildListTile(context, Icons.file_copy_outlined, 'Proofs', () => _showDummySnackbar(context, 'Proofs generated locally are not tracked for privacy')),
            _buildListTile(context, Icons.card_giftcard, 'Rewards received', () => _showDummySnackbar(context, 'Rewards sync coming in Phase 2')),
            
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
            const SizedBox(height: 120),
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


  void _showReceiveModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Receive Funds', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 100, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _walletAddress == '0x...' ? 'No wallet connected' : _walletAddress,
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Address'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _showDummySnackbar(context, 'Address copied to clipboard!');
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showSendModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send Funds', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Recipient Address (0x...)',
                  hintStyle: const TextStyle(color: AppColors.secondaryText),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Amount (ETH)',
                  hintStyle: const TextStyle(color: AppColors.secondaryText),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () {
                    Navigator.pop(context);
                    _showDummySnackbar(context, 'Send functionality will interact with BlockchainService soon.');
                  },
                  child: const Text('Send Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
