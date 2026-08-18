import 'package:flutter/material.dart';
import '../theme.dart';

class CheckEligibilityScreen extends StatelessWidget {
  const CheckEligibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Eligibility', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available Programs',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Let PrivatePilot scan your local data to see what you qualify for.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildEligibilityCard('Shopify Cashback', 'Requires spending > \$100/mo', true),
                    const SizedBox(height: 16),
                    _buildEligibilityCard('Student Support Grant', 'Requires active enrollment', false),
                    const SizedBox(height: 16),
                    _buildEligibilityCard('Freelancer Relief', 'Requires income < \$50k', true),
                  ],
                ),
              ),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Run Private Scan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEligibilityCard(String title, String condition, bool checked) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mutedGrey),
      ),
      child: Row(
        children: [
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
          Icon(checked ? Icons.check_circle : Icons.circle_outlined, color: checked ? AppColors.secondaryAccent : AppColors.secondaryText),
        ],
      ),
    );
  }
}
