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
import 'programs_screen.dart';
import 'transaction_history_screen.dart';
import '../widgets/transaction_details_modal.dart';

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
  List<Map<String, dynamic>> _transactions = [];
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
    final txs = await DatabaseService().getTransactions();
    if (mounted) {
      setState(() {
        _totalBalance = balance ?? '0.00';
        _ethBalance = eth ?? '0.00';
        _arcBalance = arc ?? '0.00';
        _githubPrs = prs ?? '0';
        _transactions = txs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/veil_logo.svg',
          height: 28,
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPress: () async {
              // Developer tool to reset state and clear the claim nullifier
              await UserSecretService.resetSecret();
              await DatabaseService().updateMetric('github_prs', '0', 'reclaim');
              await _loadMetrics();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('State reset. Nullifier cleared.', style: TextStyle(color: Colors.white)),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(bottom: 112, left: 24, right: 24),
                  )
                );
              }
            },
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryAccent,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
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
              

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryAccent,
                      AppColors.primaryAccent.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
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
                          child: CircularProgressIndicator(color: Colors.white),
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
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Multi-Chain', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                                      ]
                                    ),
                                    child: const Text('Connect', style: TextStyle(color: AppColors.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_outlined, size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text('Shielded', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                                _buildInnerBalanceContent('USDC', _arcBalance, 'Arc Testnet'),
                                _buildInnerBalanceContent('ETH', _ethBalance, 'Ethereum Sepolia'),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 32),

              // Action Cards
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckEligibilityScreen()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryAccent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ]
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome, color: Colors.black, size: 24),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Check Eligibility', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5)),
                            SizedBox(height: 4),
                            Text('See which programs you qualify for', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Active Programs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Programs', style: Theme.of(context).textTheme.titleLarge),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgramsScreen()));
                    },
                    child: const Text('View all', style: TextStyle(color: AppColors.primaryAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()));
                    },
                    child: const Text('View all', style: TextStyle(color: AppColors.primaryAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No recent activity', style: TextStyle(color: AppColors.secondaryText))),
                )
              else
                ..._transactions.map((tx) {
                  return _buildActivityTile(
                    context,
                    tx['title'] as String,
                    tx['subtitle'] as String,
                    tx['amount'] as String,
                    tx['date'] as String,
                    tx['tx_hash'] as String,
                    Icons.check_circle_outline,
                    AppColors.secondaryAccent,
                  );
                }),
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
              const SizedBox(height: 120),
            ],
          ),
        ),
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
              textStyle: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.5, color: Colors.white)
            ),
          ),
          const SizedBox(width: 12),
          Text(
            symbol, 
            style: GoogleFonts.spaceGrotesk(
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(network, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildActivityTile(BuildContext context, String title, String subtitle, String amount, String date, String txHash, IconData icon, Color iconColor) {
    return InkWell(
      onTap: () {
        TransactionDetailsModal.show(context, {
          'title': title,
          'subtitle': subtitle,
          'amount': amount,
          'date': date,
          'tx_hash': txHash,
          'color_index': iconColor == AppColors.primaryAccent ? 0 : (iconColor == Colors.purpleAccent ? 1 : 2)
        });
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
