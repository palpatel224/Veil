import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/wallet_service.dart';
import '../services/user_secret_service.dart';
import '../models/program.dart';
import 'data_sources_screen.dart';
import 'check_eligibility_screen.dart';
import 'generate_proof_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _totalBalance = '0.00';
  String _ethBalance = '0.00';
  String _arcBalance = '0.00';
  String _githubPrs = '0';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final balance = await DatabaseService().getMetric('total_balance');
    final eth = await DatabaseService().getMetric('eth_balance');
    final arc = await DatabaseService().getMetric('arc_balance');
    final prs = await DatabaseService().getMetric('github_prs');
    if (mounted) {
      setState(() {
        _totalBalance = balance ?? '0.00';
        _ethBalance = eth ?? '0.00';
        _arcBalance = arc ?? '0.00';
        _githubPrs = prs ?? '0';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryAccent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            final db = DatabaseService();
            final address = await db.getMetric('recipient_wallet');
            if (address != null && address.isNotEmpty) {
              try {
                // Fetch live from multiple networks
                final balances = await WalletService.fetchBalances(address);
                await db.updateMetric('eth_balance', balances['ETH']!.toStringAsFixed(4), 'sepolia_rpc');
                await db.updateMetric('total_balance', balances['USDC']!.toStringAsFixed(4), 'sepolia_usdc');
                await db.updateMetric('arc_balance', balances['ARC']!.toStringAsFixed(4), 'arc_testnet_rpc');
              } catch (_) {}
            }
            await _loadMetrics();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                      GestureDetector(
                        onLongPress: () async {
                          // Developer tool to reset state and clear the claim nullifier
                          await UserSecretService.resetSecret();
                          await DatabaseService().updateMetric('github_prs', '0', 'reclaim');
                          await _loadMetrics();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Dev: Reset User Secret & PRs. You can claim again.'))
                            );
                          }
                        },
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryAccent,
                          child: Icon(Icons.person, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              
              // Total Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Balance', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface.withValues(alpha: 0.6),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.mutedGrey.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.05),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    )
                  ]
                ),
                child: _isLoading 
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(color: AppColors.primaryAccent),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(color: AppColors.primaryAccent, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Multi-Chain', style: TextStyle(color: AppColors.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              if (_totalBalance == '0.00' && _ethBalance == '0.00' && _arcBalance == '0.00')
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DataSourcesScreen())).then((_) => _loadMetrics());
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(color: AppColors.primaryAccent.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))
                                      ]
                                    ),
                                    child: const Text('Connect', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.mutedGrey),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_outlined, size: 14, color: AppColors.secondaryText),
                                      SizedBox(width: 6),
                                      Text('Shielded', style: TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 60,
                            child: PageView(
                              scrollDirection: Axis.vertical,
                              children: [
                                _buildInnerBalanceContent('USDC', _totalBalance, 'Ethereum Sepolia'),
                                _buildInnerBalanceContent('ARC', _arcBalance, 'Arc Testnet'),
                                _buildInnerBalanceContent('ETH', _ethBalance, 'Ethereum Sepolia'),
                              ],
                            ),
                          ),
                        ],
                      ),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: availablePrograms.map((program) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _buildActiveProgramCard(context, program),
                    )).toList(),
                  ),
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

  Widget _buildInnerBalanceContent(String symbol, String amount, String network) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            amount, 
            style: GoogleFonts.spaceGrotesk(
              textStyle: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.5)
            ),
          ),
          const SizedBox(width: 12),
          Text(
            symbol, 
            style: GoogleFonts.spaceGrotesk(
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.secondaryText, fontWeight: FontWeight.w600)
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(network, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool _isEligible(Program program) {
    double userBalance = double.tryParse(_totalBalance) ?? 0.0;
    int userPrs = int.tryParse(_githubPrs) ?? 0;
    return userBalance >= program.requiredMinBalance && userPrs >= program.requiredMinPrs;
  }

  Widget _buildActiveProgramCard(BuildContext context, Program program) {
    bool eligible = _isEligible(program);
    Color statusColor = eligible ? AppColors.primaryAccent : Colors.orangeAccent;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => CheckEligibilityScreen(initialProgram: program)));
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.mutedGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.stars, color: statusColor, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(eligible ? Icons.check_circle : Icons.warning_amber_rounded, size: 10, color: statusColor),
                      const SizedBox(width: 4),
                      Text(eligible ? 'Eligible' : 'Req Data', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    ]
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(program.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(program.description, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w400)),
            const SizedBox(height: 12),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.mutedGrey, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: eligible ? 1.0 : 0.2,
                child: Container(
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Req: ${program.requiredMinBalance} USDC', style: const TextStyle(color: AppColors.secondaryText, fontSize: 10, fontWeight: FontWeight.w600)),
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
