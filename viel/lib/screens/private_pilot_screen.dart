import 'package:flutter/material.dart';
import '../theme.dart';
import 'generate_proof_screen.dart';

class PrivatePilotScreen extends StatelessWidget {
  const PrivatePilotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PrivatePilot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
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
                  const SizedBox(height: 40),
                  const Text('What would you like to know?', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPromptChip('Do I qualify for any programs?'),
                      _buildPromptChip('Analyze my spending'),
                      _buildPromptChip('What rewards can I claim?'),
                      _buildPromptChip('Check my eligibility'),
                    ],
                  ),
                  const SizedBox(height: 64),
                  
                  // Mock Conversation
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.mutedGrey)),
                      child: const Text('Do I qualify for the Student Support Grant?', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(backgroundColor: AppColors.primaryAccent, radius: 16, child: Icon(Icons.auto_awesome, size: 16, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4)),
                            border: Border.all(color: AppColors.mutedGrey),
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

  Widget _buildPromptChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mutedGrey),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
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
