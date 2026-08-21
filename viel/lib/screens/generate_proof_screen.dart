import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/proof_service.dart';
import '../services/blockchain_service.dart';
import '../services/database_service.dart';
import '../services/user_secret_service.dart';
import '../models/program.dart';

class GenerateProofScreen extends StatefulWidget {
  final Program? program;
  const GenerateProofScreen({super.key, this.program});

  @override
  State<GenerateProofScreen> createState() => _GenerateProofScreenState();
}

class _GenerateProofScreenState extends State<GenerateProofScreen> {
  bool _isGenerating = false;
  bool _isSubmitted = false;
  String _statusText = '';
  String? _txHash;
  String? _explorerUrl;
  String? _errorText;

  // ── Private key that pays gas (deployer key for demo).
  // In production: replace with WalletConnect session signing.
  static const String _demoPrivateKey =
      '0xc0fd611ae0d8e3cd1a4f0da76ce8c8b36689f9791f883f1aea57757fbd4017c8';

  // Unique per-device secret for nullifier derivation — loaded from secure storage.
  // Generated once on first launch, persisted via flutter_secure_storage.
  String _userSecret = '';

  // Loaded from DB — set by the user once, persisted across sessions.
  String? _recipientAddress;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load both in parallel
    final results = await Future.wait([
      UserSecretService.getOrCreateSecret(),
      DatabaseService().getMetric('recipient_wallet'),
    ]);
    if (mounted) {
      setState(() {
        _userSecret = results[0] as String;
        final wallet = results[1] as String?;
        if (wallet != null && wallet.isNotEmpty) {
          _recipientAddress = wallet;
        }
      });
    }
  }

  /// Shows a dialog asking the user for their Ethereum address.
  /// Saves it to DB so it's only asked once.
  Future<String?> _promptForWalletAddress() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Enter Your Wallet Address',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the Ethereum Sepolia address that should receive the reward.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '0x...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.mutedGrey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryAccent),
            onPressed: () async {
              final addr = controller.text.trim();
              if (addr.startsWith('0x') && addr.length == 42) {
                // Save to DB for future sessions
                await DatabaseService().updateMetric('recipient_wallet', addr, 'user');
                if (ctx.mounted) Navigator.pop(ctx, addr);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Invalid address — must start with 0x and be 42 chars')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _generateProof() async {
    // ── Guard: ensure user secret is loaded (async init) ────────────────────
    if (_userSecret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Initializing secure storage, please try again.')),
      );
      return;
    }

    // ── Ensure we have a recipient address before starting ───────────────────
    String? recipient = _recipientAddress;
    if (recipient == null || recipient.isEmpty) {
      recipient = await _promptForWalletAddress();
      if (recipient == null) return; // user cancelled
      setState(() => _recipientAddress = recipient);
    }

    // Start loading state AFTER we have the address
    setState(() {
      _isGenerating = true;
      _errorText = null;
      _statusText = 'Extracting local features...';
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _statusText = 'Verifying signature & generating Noir Proof...');

    try {
      if (widget.program == null) throw Exception('No program selected');

      // ── Step 1: Generate the ZK proof on-device ──────────────────────────
      final proofResult = await ProofService.generateProof(
        minBalance: widget.program!.requiredMinBalance,
        minPrs: widget.program!.requiredMinPrs,
        onStatus: (status) {
          if (mounted) setState(() => _statusText = status);
        },
      );

      if (!mounted) return;

      if (proofResult['success'] != true) {
        setState(() {
          _isGenerating = false;
          _errorText = proofResult['error'] ?? 'Proof generation failed';
        });
        return;
      }

      // ── Step 2: Submit proof to blockchain ───────────────────────────────
      setState(() => _statusText = 'Proof generated! Submitting to Ethereum Sepolia...');

      final claimResult = await BlockchainService.submitProof(
        programId: widget.program!.id + 1, // on-chain IDs are 1-indexed
        proofHex: proofResult['proof'] as String,
        publicInputs: List<String>.from(proofResult['publicInputs'] as List),
        userSecret: _userSecret,
        recipientAddress: recipient,
        privateKeyHex: _demoPrivateKey,
        onStatus: (status) {
          if (mounted) setState(() => _statusText = status);
        },
      );

      if (!mounted) return;

      if (claimResult.success) {
        setState(() {
          _isGenerating = false;
          _isSubmitted = true;
          _txHash = claimResult.txHash;
          _explorerUrl = claimResult.explorerUrl;
        });
      } else {
        setState(() {
          _isGenerating = false;
          _errorText = claimResult.error;
          _txHash = claimResult.txHash;
          _explorerUrl = claimResult.explorerUrl;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorText = 'Unexpected error: $e';
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
    // ── Error State ────────────────────────────────────────────────────────────
    if (_errorText != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 72),
            const SizedBox(height: 24),
            const Text('Submission Failed',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Text(
                _errorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_txHash != null) ...[
              _buildTransactionCard(),
              const SizedBox(height: 16),
              // View on Etherscan
              OutlinedButton.icon(
                onPressed: _explorerUrl != null
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_explorerUrl!)),
                        );
                      }
                    : null,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View on Etherscan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryAccent,
                  side: const BorderSide(color: AppColors.secondaryAccent),
                ),
              ),
              const SizedBox(height: 24),
            ],

            ElevatedButton(
              onPressed: () => setState(() {
                _errorText = null;
                _txHash = null;
                _explorerUrl = null;
              }),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface),
              child: const Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // ── Success State ──────────────────────────────────────────────────────────
    if (_isSubmitted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.secondaryAccent, size: 80),
            const SizedBox(height: 24),
            const Text('Proof Verified On-Chain!',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Your ZK proof was accepted and\n0.01 sETH reward has been sent.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText, fontSize: 15),
            ),
            const SizedBox(height: 32),

            // Transaction hash card
            if (_txHash != null) ...[
              _buildTransactionCard(),
              const SizedBox(height: 16),

              // View on Etherscan
              OutlinedButton.icon(
                onPressed: _explorerUrl != null
                    ? () {
                        // url_launcher would open this — for now show the URL
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_explorerUrl!)),
                        );
                      }
                    : null,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View on Etherscan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryAccent,
                  side: BorderSide(color: AppColors.secondaryAccent.withValues(alpha: 0.5)),
                ),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Back to Dashboard',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
        
        if (widget.program == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            child: const Text('No program selected. Please go back to Check Eligibility.', style: TextStyle(color: Colors.white)),
          )
        else
          _buildProofOption(widget.program!.name, widget.program!.description, Icons.verified),
        
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
  Widget _buildTransactionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isSubmitted ? AppColors.secondaryAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transaction Hash',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  _txHash!,
                  style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.secondaryText, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _txHash!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tx hash copied!')),
                  );
                },
              ),
            ],
          ),
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
