import 'package:flutter/material.dart';
import '../theme.dart';
import 'check_eligibility_screen.dart';
import '../models/program.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    _buildFilterChip('All'),
                    _buildFilterChip('Cashback'),
                    _buildFilterChip('Grants'),
                    _buildFilterChip('Scholarships'),
                    _buildFilterChip('Refunds'),
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
              ...availablePrograms.map((program) => _buildSmallProgramCard(context, program)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.white : AppColors.mutedGrey),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _buildSmallProgramCard(BuildContext context, Program program) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
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
                  Text(program.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Sponsored by ${program.sponsor}', style: const TextStyle(color: AppColors.primaryAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Text(program.description, style: const TextStyle(color: AppColors.secondaryText, fontSize: 16)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.primaryAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.primaryAccent),
                        const SizedBox(width: 12),
                        Text('Reward: ${program.reward}', style: const TextStyle(color: AppColors.primaryAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CheckEligibilityScreen(initialProgram: program)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Check Eligibility →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          );
        },
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
                    Text(program.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(program.description, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(program.reward, style: const TextStyle(color: AppColors.secondaryAccent, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
