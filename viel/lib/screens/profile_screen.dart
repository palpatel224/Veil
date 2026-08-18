import 'package:flutter/material.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
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
                  const Text('₹10,124.09', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedGrey, foregroundColor: Colors.white),
                          child: const Text('Receive'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
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
            _buildListTile(Icons.account_balance_wallet_outlined, 'Balance'),
            _buildListTile(Icons.history, 'Transaction history'),
            
            const SizedBox(height: 24),
            _buildSectionHeader('My Activity'),
            _buildListTile(Icons.verified_outlined, 'Claims'),
            _buildListTile(Icons.file_copy_outlined, 'Proofs'),
            _buildListTile(Icons.card_giftcard, 'Rewards received'),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Private Data'),
            _buildListTile(Icons.sync_alt, 'Connected accounts'),
            _buildListTile(Icons.sd_storage_outlined, 'Local storage'),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Settings'),
            _buildListTile(Icons.security, 'Security & Privacy'),
            _buildListTile(Icons.palette_outlined, 'Appearance'),
            _buildListTile(Icons.help_outline, 'Help & Support'),
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

  Widget _buildListTile(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.mutedGrey)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 12),
      onTap: () {},
    );
  }
}
