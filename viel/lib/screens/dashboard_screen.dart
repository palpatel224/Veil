import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import 'check_eligibility_screen.dart';
import 'generate_proof_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/veil_logo.svg',
                    height: 28,
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
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
                                child: const Row(
                                  children: [
                                    Icon(Icons.notifications_off_outlined, color: AppColors.primaryAccent, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No new notifications',
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                            )
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.mutedGrey)),
                          child: const Icon(Icons.notifications_none, size: 20, color: AppColors.primaryText),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryAccent,
                        child: Icon(Icons.person, size: 20, color: Colors.white),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              
              // Total Balance
              Text('Total balance', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\$10,124.09', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.secondaryText),
                          const SizedBox(width: 6),
                          Text('Private & Verifiable', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_off_outlined, size: 14, color: AppColors.primaryAccent),
                        SizedBox(width: 6),
                        Text('Shielded', style: TextStyle(color: AppColors.primaryAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),

              // Action Cards
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Check Eligibility',
                      subtitle: 'See which programs you qualify for',
                      icon: Icons.auto_awesome,
                      color: AppColors.primaryAccent,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckEligibilityScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: 'Generate Proof',
                      subtitle: 'Prove any condition privately',
                      icon: Icons.upload_file,
                      color: AppColors.secondaryAccent,
                      textColor: Colors.black,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GenerateProofScreen()));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Active Programs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Programs', style: Theme.of(context).textTheme.titleLarge),
                  const Text('View all', style: TextStyle(color: AppColors.primaryAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildActiveProgramCard(context, 'Shopify Cashback', '\$25.40', '80% completed', 'Eligible', Colors.green, Icons.shopping_bag),
                    const SizedBox(width: 16),
                    _buildActiveProgramCard(context, 'Uni Scholarship', '\$1,200', '60% completed', 'In Progress', AppColors.primaryAccent, Icons.school),
                    const SizedBox(width: 16),
                    _buildActiveProgramCard(context, 'Uber Rewards', '\$15.00', 'Submitted', 'Pending', Colors.orange, Icons.local_taxi),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
                  const Text('View all', style: TextStyle(color: AppColors.primaryAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              _buildActivityTile(context, 'Proof Verified', 'Shopify Cashback', '+\$25.40', 'May 18, 2025', Icons.check_circle_outline, AppColors.secondaryAccent),
              _buildActivityTile(context, 'Proof Submitted', 'Uni Scholarship', '-\$1.20', 'May 18, 2025', Icons.send_outlined, AppColors.primaryAccent),
              _buildActivityTile(context, 'Payment Received', 'Uber Rewards', '+\$15.00', 'May 15, 2025', Icons.download_outlined, Colors.white),
              const SizedBox(height: 32),

              // Privacy Reassurance
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.mutedGrey),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primaryAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.shield_outlined, color: AppColors.primaryAccent),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your privacy is protected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          SizedBox(height: 4),
                          Text('Computation happens on your device. Only proofs are shared.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required Color textColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: textColor, size: 20),
            ),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 12)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward_ios, color: textColor, size: 14),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProgramCard(BuildContext context, String title, String amount, String progress, String status, Color statusColor, IconData icon) {
    return GestureDetector(
      onTap: () {
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
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Status: $status', style: TextStyle(color: statusColor, fontSize: 16)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primaryAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.primaryAccent),
                      const SizedBox(width: 12),
                      Text('Progress: $progress', style: const TextStyle(color: AppColors.primaryAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.mutedGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: statusColor, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                )
              ],
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(amount, style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.mutedGrey, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.8, // mockup
                child: Container(decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
              ),
            ),
            const SizedBox(height: 8),
            Text(progress, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(BuildContext context, String title, String subtitle, String amount, String date, IconData icon, Color iconColor) {
    return InkWell(
      onTap: () {
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
                const Text('Transaction Details', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status', style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                    Text(title, style: TextStyle(color: iconColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Program', style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount', style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                    Text(amount, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Date', style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                    Text(date, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.mutedGrey)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: TextStyle(color: amount.startsWith('+') ? AppColors.secondaryAccent : Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 12),
          ],
        ),
      ),
    );
  }
}
