import 'package:flutter/material.dart';
import '../theme.dart';
import 'check_eligibility_screen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.mutedGrey),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: AppColors.secondaryText),
                      hintText: 'Search programs...',
                      hintStyle: TextStyle(color: AppColors.secondaryText),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildFilterChip('All', true),
                    _buildFilterChip('Cashback', false),
                    _buildFilterChip('Grants', false),
                    _buildFilterChip('Scholarships', false),
                    _buildFilterChip('Refunds', false),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('For You', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.primaryAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryAccent),
                          ),
                          const Spacer(),
                          const Text('₹2,000 Reward', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('PRIVATE CASHBACK', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('Spending < ₹20,000/month', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                      const SizedBox(height: 24),
                      const Text('Your data stays private.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckEligibilityScreen()));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: Colors.white),
                          child: const Text('Check Eligibility →'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('More Programs', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              _buildSmallProgramCard('Student Grants', 'Income < \$50k', 'Up to \$1k'),
              _buildSmallProgramCard('Purchase Refunds', 'Verified purchase', 'Full Refund'),
              _buildSmallProgramCard('DAO Contributor', 'Reputation > 85', '500 Tokens'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.white : AppColors.mutedGrey),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildSmallProgramCard(String title, String subtitle, String reward) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
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
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                ],
              ),
            ),
            Text(reward, style: const TextStyle(color: AppColors.secondaryAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
