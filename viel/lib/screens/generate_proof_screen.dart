import 'package:flutter/material.dart';
import '../theme.dart';

class GenerateProofScreen extends StatelessWidget {
  const GenerateProofScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Proof', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate a ZK Proof',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a cryptographic proof of your data without revealing the underlying information.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              _buildProofOption('Income Verification', 'Prove income > \$50k', Icons.attach_money),
              const SizedBox(height: 16),
              _buildProofOption('Academic Standing', 'Prove GPA > 3.0', Icons.school),
              const SizedBox(height: 16),
              _buildProofOption('Employment Status', 'Prove active employment', Icons.work),
              
              const Spacer(),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: AppColors.primaryAccent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Proofs are generated locally. The blockchain only receives the zero-knowledge proof, preserving your privacy.',
                        style: TextStyle(color: AppColors.primaryAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Generate & Submit', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProofOption(String title, String condition, IconData icon) {
    return Container(
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
            decoration: BoxDecoration(color: AppColors.primaryAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(condition, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText, size: 14),
        ],
      ),
    );
  }
}
