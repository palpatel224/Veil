import 'package:flutter/material.dart';
import '../theme.dart';
import 'generate_proof_screen.dart';

class PrivatePilotScreen extends StatefulWidget {
  const PrivatePilotScreen({super.key});

  @override
  State<PrivatePilotScreen> createState() => _PrivatePilotScreenState();
}

class _PrivatePilotScreenState extends State<PrivatePilotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  void _sendMessage(String text, {bool isEligibility = false}) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
      _controller.clear();
    });
    
    _scrollToBottom();

    // Mock network/computation delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        if (isEligibility || text.toLowerCase().contains('eligib') || text.toLowerCase().contains('qualify')) {
          _messages.add({
            'role': 'bot',
            'text': 'You appear to meet the eligibility requirements for the Student Support Grant based on your local data.',
            'isEligibility': true
          });
        } else {
          _messages.add({
            'role': 'bot',
            'text': 'I analyzed your local private data. Based on the current parameters, everything seems in order. Is there anything else you would like to check?',
            'isEligibility': false
          });
        }
      });
      _scrollToBottom();
    });
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
                        _buildPromptCard('Check Eligibility', 'See if you qualify for programs without revealing data.', Icons.verified_user_outlined, true),
                        const SizedBox(height: 16),
                        _buildPromptCard('Analyze Spending', 'Get local insights based on your transaction history.', Icons.insights_outlined, false),
                      ],
                    ),
                  ),
                ] else ...[
                  // Chat Messages
                  ..._messages.map((msg) => Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: msg['role'] == 'user' ? _buildUserMessage(msg['text']) : _buildBotMessage(msg['text'], msg['isEligibility'] ?? false),
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

  Widget _buildBotMessage(String text, bool isEligibility) {
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
                        _buildCheckRow('Income criteria met'),
                        _buildCheckRow('Academic standing verified'),
                        _buildCheckRow('Enrollment status active'),
                        const Divider(color: AppColors.mutedGrey, height: 24),
                        Row(
                          children: [
                            const Icon(Icons.verified, color: AppColors.secondaryAccent, size: 20),
                            const SizedBox(width: 8),
                            const Text('Eligible for Proof', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GenerateProofScreen()));
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

  Widget _buildCheckRow(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.secondaryAccent, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 14)),
        ],
      ),
    );
  }
}
