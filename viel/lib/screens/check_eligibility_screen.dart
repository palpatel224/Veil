import 'package:flutter/material.dart';
import '../theme.dart';
import 'generate_proof_screen.dart';

class CheckEligibilityScreen extends StatefulWidget {
  const CheckEligibilityScreen({super.key});

  @override
  State<CheckEligibilityScreen> createState() => _CheckEligibilityScreenState();
}

class _CheckEligibilityScreenState extends State<CheckEligibilityScreen> {
  bool _isScanning = false;
  bool _hasScanned = false;

  void _runScan() async {
    setState(() {
      _isScanning = true;
    });
    
    // Simulate local private pilot scanning
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isScanning = false;
        _hasScanned = true;
      });
    }
  }

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
                    _buildEligibilityCard('Shopify Cashback', 'Requires spending > \$100/mo', _hasScanned ? true : false),
                    const SizedBox(height: 16),
                    _buildEligibilityCard('Student Support Grant', 'Requires active enrollment', false),
                    const SizedBox(height: 16),
                    _buildEligibilityCard('Freelancer Relief', 'Requires income < \$50k', _hasScanned ? true : false),
                  ],
                ),
              ),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isScanning 
                      ? null 
                      : (_hasScanned 
                          ? () {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GenerateProofScreen()));
                            } 
                          : _runScan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasScanned ? AppColors.secondaryAccent : AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isScanning
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _hasScanned ? 'Proceed to Proof' : 'Run Private Scan', 
                          style: TextStyle(color: _hasScanned ? Colors.black : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEligibilityCard(String title, String condition, bool checked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: checked ? AppColors.secondaryAccent.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: checked ? AppColors.secondaryAccent.withValues(alpha: 0.5) : AppColors.mutedGrey),
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
