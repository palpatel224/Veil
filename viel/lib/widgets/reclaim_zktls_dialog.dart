import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';


class ReclaimZkTlsDialog extends StatefulWidget {
  final String providerName;
  final String targetUrl;
  final IconData icon;
  final Color color;
  final Function(Map<String, dynamic> extractedData, Map<String, String> signatureData) onSuccess;

  const ReclaimZkTlsDialog({
    super.key,
    required this.providerName,
    required this.targetUrl,
    required this.icon,
    required this.color,
    required this.onSuccess,
  });

  @override
  State<ReclaimZkTlsDialog> createState() => _ReclaimZkTlsDialogState();
}

class _ReclaimZkTlsDialogState extends State<ReclaimZkTlsDialog> {
  int _step = 0;
  final List<String> _logs = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startZkTlsFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addLog(String log) {
    if (mounted) {
      setState(() {
        _logs.add(log);
      });
    }
  }

  void _startZkTlsFlow() async {
    // Step 0: Initializing WebView
    _addLog("> Initializing secure WebView...");
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Step 1: Navigating to Target
    setState(() => _step = 1);
    _addLog("> Navigating to ${widget.targetUrl}");
    await Future.delayed(const Duration(milliseconds: 1200));

    // Step 2: User 'Logs In' (Simulated)
    setState(() => _step = 2);
    _addLog("> Waiting for user authentication...");
    await Future.delayed(const Duration(seconds: 2));

    // Step 3: Intercepting TLS
    setState(() => _step = 3);
    _addLog("> HTTPS response detected.");
    _addLog("> Reclaim Node intercepting TLS Session Keys...");
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Step 4: Extracting JSON
    _addLog("> Parsing JSON payload for private data...");
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Step 5: Generating Cryptographic Signature
    setState(() => _step = 4);
    _addLog("> Reclaim Node signing payload hash (ECDSA secp256k1)...");
    await Future.delayed(const Duration(milliseconds: 1500));
    _addLog("> Signature generated: 0xd337dcbd8b49249c...");

    // Completion
    if (mounted) {
      _addLog("> Process Complete. Storing in Secure Enclave.");
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Mock extracted data based on provider
      Map<String, dynamic> data = {};
      if (widget.providerName.contains("GitHub")) {
        data = {"github_prs": "3"};
      } else {
        data = {"total_balance": "10124.09"};
      }

      // Mock Signature Data (to match our Noir Python script)
      Map<String, String> sigData = {
        "signature": "d337dcbd8b49249c3a411042048fb0491061a0be169ccb42e6a77d95e0ede1d922945021d9649dbe03b7d91b599698b40b40850ea284256eb490da8cc3640234",
        "payloadHash": "f75f816063ff0249e5dd35d5843a7cfc90bc6d4e469ba72cc0c811c15642400d"
      };

      widget.onSuccess(data, sigData);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: widget.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reclaim zkTLS: ${widget.providerName}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Progress Indicator
            LinearProgressIndicator(
              value: (_step + 1) / 5,
              backgroundColor: AppColors.mutedGrey,
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
            const SizedBox(height: 24),
            // Terminal Log View
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.mutedGrey),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Please do not close this window.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
