import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/llm_service.dart';
import '../services/wallet_service.dart';
import '../services/database_service.dart';
import '../models/program.dart';
import 'generate_proof_screen.dart';

class PrivatePilotScreen extends StatefulWidget {
  const PrivatePilotScreen({super.key});

  @override
  State<PrivatePilotScreen> createState() => _PrivatePilotScreenState();
}

class _PrivatePilotScreenState extends State<PrivatePilotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LlmService _llmService = LlmService();
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _llmService.init();
  }

  Future<void> _sendMessage(String text, {bool isEligibility = false}) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
      _controller.clear();
    });
    
    _scrollToBottom();



    // Process intent via LLM
    final intentData = await _llmService.parseIntent(text);
    if (!mounted) return;

    final intent = intentData['intent'];
    String? botText;
    bool isEligibilityIntent = false;
    Program? targetProgram;
    List<Map<String, dynamic>> criteria = [];
    bool isEligible = true;

    if (intent == 'CHECK_ELIGIBILITY' || intent == 'GENERATE_PROOF') {
      final targetStrRaw = intentData['target']?.toString().toLowerCase().replaceAll('_', ' ') ?? '';
      final targetWords = targetStrRaw.split(' ').where((w) => w.length > 2).toList();
      
      // Find the closest program match
      try {
        targetProgram = availablePrograms.firstWhere(
          (p) {
            final pName = p.name.toLowerCase();
            final pSponsor = p.sponsor.toLowerCase();
            if (targetWords.isEmpty) return false;
            return targetWords.any((word) => pName.contains(word) || pSponsor.contains(word));
          }
        );
      } catch (e) {
        // Fallback to first if no match
        targetProgram = availablePrograms.isNotEmpty ? availablePrograms.first : null;
      }
      
      isEligibilityIntent = true;
      
      if (targetProgram != null) {
        // Calculate eligibility dynamically
        final db = DatabaseService();
        double userBalance = 0.0;
        final address = await db.getMetric('recipient_wallet');
        if (address != null && address.isNotEmpty) {
          try {
             final balances = await WalletService.fetchBalances(address);
             // Rough total balance equivalent in USD for evaluation
             userBalance = (balances['ETH'] ?? 0) * 3000 + (balances['USDC'] ?? 0) + (balances['ARC'] ?? 0);
          } catch (e) {}
        } else {
          final balStr = await db.getMetric('total_balance') ?? '0';
          userBalance = double.tryParse(balStr) ?? 0.0;
        }

        int userPrs = 0;
        final prsStr = await db.getMetric('github_prs') ?? '0';
        userPrs = int.tryParse(prsStr) ?? 0;

        if (targetProgram.requiredMinBalance > 0) {
          bool met = userBalance >= targetProgram.requiredMinBalance;
          if (!met) isEligible = false;
          criteria.add({'label': 'Balance >= \$${targetProgram.requiredMinBalance}', 'met': met});
        }
        if (targetProgram.requiredMinPrs > 0) {
          bool met = userPrs >= targetProgram.requiredMinPrs;
          if (!met) isEligible = false;
          criteria.add({'label': 'GitHub PRs >= ${targetProgram.requiredMinPrs}', 'met': met});
        }
        if (criteria.isEmpty) {
          criteria.add({'label': 'No special requirements', 'met': true});
        }
      }

      if (intent == 'CHECK_ELIGIBILITY') {
        if (isEligible) {
          botText = 'I analyzed your local private data for ${targetProgram?.name ?? 'the program'}. You appear to meet the eligibility requirements.';
        } else {
          botText = 'I analyzed your local private data for ${targetProgram?.name ?? 'the program'}. You do not currently meet all the requirements.';
        }
      } else {
        if (isEligible) {
           botText = 'Ready to generate a zero-knowledge proof for ${targetProgram?.name ?? 'the program'}.';
        } else {
           botText = 'You do not meet the requirements to generate a proof for ${targetProgram?.name ?? 'the program'}.';
        }
      }
    } else if (intent == 'FIND_ELIGIBLE_PROGRAMS') {
      final db = DatabaseService();
      double userBalance = 0.0;
      final address = await db.getMetric('recipient_wallet');
      if (address != null && address.isNotEmpty) {
        try {
           final balances = await WalletService.fetchBalances(address);
           userBalance = (balances['ETH'] ?? 0) * 3000 + (balances['USDC'] ?? 0) + (balances['ARC'] ?? 0);
        } catch (e) {}
      } else {
        final balStr = await db.getMetric('total_balance') ?? '0';
        userBalance = double.tryParse(balStr) ?? 0.0;
      }

      int userPrs = 0;
      final prsStr = await db.getMetric('github_prs') ?? '0';
      userPrs = int.tryParse(prsStr) ?? 0;

      List<Program> eligible = [];
      for (var p in availablePrograms) {
        if ((p.requiredMinBalance == 0 || userBalance >= p.requiredMinBalance) && 
            (p.requiredMinPrs == 0 || userPrs >= p.requiredMinPrs)) {
          eligible.add(p);
        }
      }

      if (eligible.isEmpty) {
        botText = 'I analyzed your local private data, but you do not currently meet the requirements for any available programs.';
      } else {
        botText = 'I analyzed your local private data. You are eligible for:\n\n' + eligible.map((p) => '• ${p.name}').join('\n');
      }
    } else if (intent == 'CHECK_BALANCE') {
      botText = 'I checked your shielded wallet. Could not retrieve balance.';
      try {
        final db = DatabaseService();
        final address = await db.getMetric('recipient_wallet');
        if (address != null && address.isNotEmpty) {
          final balances = await WalletService.fetchBalances(address);
          botText = 'I checked your shielded wallet.\n\nBalances:\nETH: ${balances['ETH']?.toStringAsFixed(4) ?? '0'}\nUSDC: ${balances['USDC']?.toStringAsFixed(2) ?? '0'}\nARC: ${balances['ARC']?.toStringAsFixed(2) ?? '0'}';
        }
      } catch (e) {
        botText = 'I checked your shielded wallet, but encountered an error: $e';
      }
    } else {
      botText = intentData['message'] ?? 'I processed your request locally.';
    }

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add({
        'role': 'bot',
        'text': botText,
        'isEligibility': isEligibilityIntent,
        'program': targetProgram,
        'criteria': criteria,
        'isEligible': isEligible,
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PrivatePilot', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              children: [
                if (_messages.isEmpty) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.mutedGrey),
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppColors.secondaryAccent, size: 48),
                        ),
                        const SizedBox(height: 24),
                        const Text('PrivatePilot', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        const Text('Your on-device AI assistant.', style: TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                        const SizedBox(height: 48),
                        _buildPromptCard('Check eligibility for Web3 Starter Grant', 'Check eligibility for a specific program.', Icons.verified_user_outlined, true),
                        const SizedBox(height: 16),
                        _buildPromptCard('Find Eligible Programs', 'Discover which grants you qualify for based on local data.', Icons.insights_outlined, false),
                        const SizedBox(height: 16),
                        _buildPromptCard('Check Shielded Balance', 'View your private wallet balances securely.', Icons.account_balance_wallet_outlined, false),
                      ],
                    ),
                  ),
                ] else ...[
                  // Chat Messages
                  ..._messages.map((msg) => Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: msg['role'] == 'user' 
                        ? _buildUserMessage(msg['text']) 
                        : _buildBotMessage(
                            msg['text'], 
                            msg['isEligibility'] ?? false, 
                            program: msg['program'],
                            criteria: msg['criteria'],
                            isEligible: msg['isEligible'] ?? false,
                          ),
                  )),
                  
                  if (_isTyping)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: AppColors.surface, radius: 16, child: Icon(Icons.auto_awesome, size: 16, color: AppColors.secondaryAccent)),
                          SizedBox(width: 12),
                          Text('Thinking locally...', style: TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          // Chat Input
          Container(
            padding: EdgeInsets.only(
              left: 20, 
              right: 20, 
              top: 16, 
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 120
            ),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.95),
              border: Border(top: BorderSide(color: AppColors.mutedGrey.withValues(alpha: 0.3))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.mutedGrey.withValues(alpha: 0.5)),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          onSubmitted: (val) => _sendMessage(val),
                          decoration: InputDecoration(
                            hintText: 'Ask anything...',
                            hintStyle: const TextStyle(color: AppColors.secondaryText),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_upward, color: AppColors.secondaryAccent),
                              onPressed: () => _sendMessage(_controller.text),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.secondaryText, size: 14),
                    SizedBox(width: 8),
                    Text('Processing runs locally. Data never leaves your device.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface, 
              borderRadius: BorderRadius.circular(24).copyWith(bottomRight: const Radius.circular(4)), 
              border: Border.all(color: AppColors.mutedGrey.withValues(alpha: 0.3))
            ),
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildBotMessage(String text, bool isEligibility, {Program? program, List<dynamic>? criteria, bool isEligible = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(backgroundColor: AppColors.surface, radius: 16, child: Icon(Icons.auto_awesome, size: 16, color: AppColors.secondaryAccent)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24).copyWith(topLeft: const Radius.circular(4)),
              border: Border.all(color: AppColors.mutedGrey.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 15)),
                if (isEligibility) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.mutedGrey.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (criteria != null)
                          ...criteria.map((c) => _buildCheckRow(c['label'] as String, isMet: c['met'] as bool)),
                        if (criteria == null)
                          _buildCheckRow('Checked eligibility locally', isMet: true),
                        
                        const Divider(color: AppColors.mutedGrey, height: 24),
                        Row(
                          children: [
                            Icon(isEligible ? Icons.verified : Icons.cancel, color: isEligible ? AppColors.secondaryAccent : Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(isEligible ? 'Eligible for Proof' : 'Not Eligible', style: TextStyle(color: isEligible ? Colors.white : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isEligible)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateProofScreen(program: program)));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Generate Proof →', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard(String title, String subtitle, IconData icon, bool triggersEligibility) {
    return InkWell(
      onTap: () => _sendMessage(title, isEligibility: triggersEligibility),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mutedGrey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.secondaryAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.secondaryAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckRow(String label, {bool isMet = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(isMet ? Icons.check_circle : Icons.cancel, color: isMet ? AppColors.secondaryAccent : Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
        ],
      ),
    );
  }
}
