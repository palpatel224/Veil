import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../models/program.dart';
import 'generate_proof_screen.dart';

class CheckEligibilityScreen extends StatefulWidget {
  final Program? initialProgram;
  const CheckEligibilityScreen({super.key, this.initialProgram});

  @override
  State<CheckEligibilityScreen> createState() => _CheckEligibilityScreenState();
}

class _CheckEligibilityScreenState extends State<CheckEligibilityScreen> {
  bool _isScanning = false;
  bool _hasScanned = false;
  double _userBalance = 0.0;
  int _userPrs = 0;
  Program? _selectedProgram;

  @override
  void initState() {
    super.initState();
    if (widget.initialProgram != null) {
      _selectedProgram = widget.initialProgram;
      _runScan();
    }
  }

  void _runScan() async {
    setState(() {
      _isScanning = true;
    });
    
    // Simulate local private pilot scanning, fetch actual data from SQLite
    final db = DatabaseService();
    final balanceStr = await db.getMetric('total_balance') ?? '0';
    final prsStr = await db.getMetric('github_prs') ?? '0';

    _userBalance = double.tryParse(balanceStr) ?? 0.0;
    _userPrs = int.tryParse(prsStr) ?? 0;

    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isScanning = false;
        _hasScanned = true;
        if (_selectedProgram != null && !_isEligible(_selectedProgram!)) {
          _selectedProgram = null;
        }
        if (_selectedProgram == null) {
          try {
            _selectedProgram = availablePrograms.firstWhere((p) => _isEligible(p));
          } catch (_) {}
        }
      });
    }
  }

  bool _isEligible(Program program) {
    if (!_hasScanned) return false;
    return _userBalance >= program.requiredMinBalance && _userPrs >= program.requiredMinPrs;
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
                child: ListView.separated(
                  itemCount: availablePrograms.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final program = availablePrograms[index];
                    final eligible = _isEligible(program);
                    final isSelected = _selectedProgram == program;
                    return _buildEligibilityCard(program, eligible, isSelected);
                  },
                ),
              ),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isScanning 
                      ? null 
                      : (!_hasScanned 
                          ? _runScan
                          : (_selectedProgram != null 
                              ? () {
                                  Navigator.pushReplacement(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (context) => GenerateProofScreen(program: _selectedProgram!),
                                    ),
                                  );
                                } 
                              : null)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasScanned && _selectedProgram != null 
                        ? AppColors.secondaryAccent 
                        : AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isScanning
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          !_hasScanned ? 'Run Private Scan' : 'Proceed to Proof', 
                          style: TextStyle(
                            color: (_hasScanned && _selectedProgram != null) ? Colors.black : Colors.white, 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEligibilityCard(Program program, bool eligible, bool isSelected) {
    return GestureDetector(
      onTap: eligible ? () {
        setState(() {
          _selectedProgram = program;
        });
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.secondaryAccent.withValues(alpha: 0.1) 
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.secondaryAccent 
                : (eligible ? AppColors.primaryAccent.withValues(alpha: 0.5) : AppColors.mutedGrey),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.secondaryAccent.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(program.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(program.description, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                ],
              ),
            ),
            if (_hasScanned)
              Icon(
                eligible ? Icons.check_circle : Icons.cancel, 
                color: eligible ? AppColors.secondaryAccent : Colors.redAccent,
              )
            else
              const Icon(Icons.circle_outlined, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
