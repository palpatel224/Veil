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
            'text': 'You appear to meet the eligibility requirements for the Student Support Grant.',
            'isEligibility': true
          });
        } else {
          _messages.add({
            'role': 'bot',
            'text': 'I analyzed your local private data. Based on the current policies, everything seems in order. Is there anything else you would like to check?',
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
      appBar: AppBar(
        title: const Text('PrivatePilot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondaryAccent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Running privately on device', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 32),
                  if (_messages.isEmpty) ...[
                    const Text('What would you like to know?', style: TextStyle(color: Colors.white, fontSize: 32, height: 1.1, letterSpacing: -0.5, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _buildPromptChip('Qualify for programs?', Icons.local_activity_outlined, true),
                          const SizedBox(width: 12),
                          _buildPromptChip('Analyze spending', Icons.insights_outlined, false),
                          const SizedBox(width: 12),
                          _buildPromptChip('Check eligibility', Icons.verified_user_outlined, true),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
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
                          CircleAvatar(backgroundColor: AppColors.secondaryAccent, radius: 18, child: Icon(Icons.auto_awesome, size: 20, color: Colors.black)),
                          SizedBox(width: 12),
                          Text('Thinking...', style: TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Chat Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 20, offset: const Offset(0, -10)),
                ]
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.mutedGrey, width: 0.5),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (val) => _sendMessage(val),
                        decoration: const InputDecoration(
                          hintText: 'Ask PrivatePilot...',
                          hintStyle: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                          border: InputBorder.none,
                          icon: Icon(Icons.auto_awesome, color: AppColors.secondaryAccent, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _sendMessage(_controller.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.mutedGrey, width: 0.5)),
                color: AppColors.surface,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.secondaryText, size: 16),
                  SizedBox(width: 8),
                  Text('Private data never leaves your device.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
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
              border: Border.all(color: AppColors.mutedGrey, width: 0.5)
            ),
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        const CircleAvatar(backgroundColor: AppColors.surface, radius: 18, child: Icon(Icons.person, size: 20, color: Colors.white)),
      ],
    );
  }

  Widget _buildBotMessage(String text, bool isEligibility) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(backgroundColor: AppColors.secondaryAccent, radius: 18, child: Icon(Icons.auto_awesome, size: 20, color: Colors.black)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24).copyWith(topLeft: const Radius.circular(4)),
              border: Border.all(color: AppColors.mutedGrey, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(color: Colors.white, height: 1.5)),
                if (isEligibility) ...[
                  const SizedBox(height: 16),
                  _buildCheckRow('Income'),
                  _buildCheckRow('Academic score'),
                  _buildCheckRow('Enrollment'),
                  const SizedBox(height: 16),
                  const Text('Eligible', style: TextStyle(color: AppColors.secondaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GenerateProofScreen()));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: Colors.white),
                      child: const Text('Generate Proof →'),
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

  Widget _buildPromptChip(String text, IconData icon, bool triggersEligibility) {
    return GestureDetector(
      onTap: () => _sendMessage(text, isEligibility: triggersEligibility),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.mutedGrey, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.secondaryAccent),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
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
          const Icon(Icons.check, color: AppColors.secondaryAccent, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}
