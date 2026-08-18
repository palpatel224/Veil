import 'package:flutter/material.dart';
import '../theme.dart';
import 'generate_proof_screen.dart';

class PrivatePilotScreen extends StatelessWidget {
  const PrivatePilotScreen({super.key});

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
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 32),
                  const Text('What would you like to know?', style: TextStyle(color: Colors.white, fontSize: 32, height: 1.1, letterSpacing: -0.5, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _buildPromptChip('Qualify for programs?', Icons.local_activity_outlined),
                        const SizedBox(width: 12),
                        _buildPromptChip('Analyze spending', Icons.insights_outlined),
                        const SizedBox(width: 12),
                        _buildPromptChip('Check eligibility', Icons.verified_user_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),
                  
                  // Mock Conversation User
                  Row(
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
                          child: const Text('Do I qualify for the Student Support Grant?', style: TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const CircleAvatar(backgroundColor: AppColors.surface, radius: 18, child: Icon(Icons.person, size: 20, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
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
                              const Text('You appear to meet the eligibility requirements.', style: TextStyle(color: Colors.white, height: 1.5)),
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            // Chat Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 20, offset: const Offset(0, -10)),
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
                      child: const TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask PrivatePilot...',
                          hintStyle: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                          border: InputBorder.none,
                          icon: Icon(Icons.auto_awesome, color: AppColors.secondaryAccent, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 24),
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

  Widget _buildPromptChip(String text, IconData icon) {
    return Container(
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
