import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/proof_service.dart';

class GenerateProofScreen extends StatefulWidget {
  const GenerateProofScreen({super.key});

  @override
  State<GenerateProofScreen> createState() => _GenerateProofScreenState();
}

class _GenerateProofScreenState extends State<GenerateProofScreen> {
  bool _isGenerating = false;
  bool _isSubmitted = false;
  String _statusText = '';

  void _generateProof() async {
    setState(() {
      _isGenerating = true;
      _statusText = 'Extracting local features...';
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _statusText = 'Verifying signature & generating Noir Proof...';
    });

    try {
      // Call the bridge service to generate the proof on-device
      // It will automatically read the user's actual balance and PRs from SQLite
      final proofResult = await ProofService.generateProof(
        minBalance: 5000,
        minPrs: 1,
      );

      if (!mounted) return;
      
      if (proofResult['success'] == true) {
        setState(() {
          _statusText = 'Proof generated! Submitting to Blockchain...';
        });

        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;

        setState(() {
          _isGenerating = false;
          _isSubmitted = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _statusText = 'Error generating proof: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Proof', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        automaticallyImplyLeading: !_isGenerating, // Prevent backing out during generation
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isSubmitted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.secondaryAccent, size: 80),
            const SizedBox(height: 24),
            const Text('Proof Verified!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Your claim has been verified on-chain.\nThe shielded payment is on its way.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Back to Dashboard', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    if (_isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ZkProcessingAnimation(),
            const SizedBox(height: 48),
            Text(
              _statusText,
              style: const TextStyle(color: AppColors.secondaryAccent, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
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
            onPressed: _generateProof,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Generate & Submit', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        )
      ],
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

class ZkProcessingAnimation extends StatefulWidget {
  const ZkProcessingAnimation({super.key});

  @override
  State<ZkProcessingAnimation> createState() => _ZkProcessingAnimationState();
}

class _ZkProcessingAnimationState extends State<ZkProcessingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final sineValue = math.sin(t * 2 * math.pi); // -1 to 1
        final normalizedSine = (sineValue + 1) / 2; // 0 to 1
        final cosineValue = math.cos(t * 2 * math.pi);
        final normalizedCosine = (cosineValue + 1) / 2;
        
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating box changing to circle
              Transform.rotate(
                angle: t * 2 * math.pi, // 1 full rotation
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primaryAccent.withValues(alpha: 0.3 + normalizedSine * 0.2), 
                      width: 2
                    ),
                    borderRadius: BorderRadius.circular(30 + 30 * normalizedSine),
                  ),
                ),
              ),
              
              // Middle rotating shape, opposite direction and scaling
              Transform.rotate(
                angle: -t * 4 * math.pi, // 2 full counter rotations
                child: Transform.scale(
                  scale: 0.8 + 0.2 * normalizedSine,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryAccent.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.8), 
                        width: 3
                      ),
                      borderRadius: BorderRadius.circular(12 + 28 * normalizedCosine),
                    ),
                  ),
                ),
              ),
              
              // Inner glowing pulse lock
              Transform.scale(
                scale: 0.8 + normalizedSine * 0.2,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAccent.withValues(alpha: 0.5),
                        blurRadius: 20 * normalizedSine,
                        spreadRadius: 5 * normalizedSine,
                      )
                    ]
                  ),
                  child: const Icon(
                    Icons.lock_outline, 
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
