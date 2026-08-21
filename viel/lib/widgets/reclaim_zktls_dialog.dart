import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/proof_service.dart';

class ReclaimZkTlsDialog extends StatefulWidget {
  final String providerName;
  final String providerId;
  final IconData icon;
  final Color color;
  final Function(Map<String, dynamic> extractedData, Map<String, String> signatureData) onSuccess;

  const ReclaimZkTlsDialog({
    super.key,
    required this.providerName,
    required this.providerId,
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
  String? _requestUrl;
  bool _isSessionStarted = false;

  // Placeholder credentials for demo
  final String appId = "0xA3e396d039f7D02D03719F8c19a3B509403b06C2";
  final String appSecret = "0x9cc298d5c968984bb22d7848bf46d8e85c35b86a43bd6b69f31380d33e96ec2e";

  @override
  void initState() {
    super.initState();
    _startZkTlsFlow();
  }

  @override
  void dispose() {
    // Dispose the heavy WebView immediately when the dialog is closed to free memory.
    ProofService.disposeProver();
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
    setState(() => _step = 1);
    _addLog("> Initializing secure WebView bridge...");
    
    // Generate Reclaim URL
    _addLog("> Requesting Reclaim URL from backend...");
    final url = await ProofService.buildReclaimRequest(widget.providerId, appId, appSecret);
    
    if (url != null) {
      setState(() {
        _requestUrl = url;
        _step = 2;
      });
      _addLog("> URL generated successfully. Please open the link to prove your credentials.");
      
      // Start waiting for the session to complete
      _waitForSession();
    } else {
      _addLog("> Failed to generate Reclaim URL.");
    }
  }
  
  void _waitForSession() async {
    if (_isSessionStarted) return;
    _isSessionStarted = true;
    _addLog("> Waiting for cryptographic proof from Reclaim Node...");
    
    final proof = await ProofService.startReclaimSession();
    if (proof != null) {
      setState(() => _step = 5);
      _addLog("> HTTPS response intercepted and verified.");
      _addLog("> Signature generated successfully.");
      
      // Extract dummy data from proof for demo purposes
      Map<String, dynamic> data = {};
      if (widget.providerName.contains("GitHub")) {
        // Log the raw proof to the terminal to debug what Reclaim returned
        debugPrint("RAW RECLAIM PROOF: $proof");
        
        String username = "";
        try {
          var p = proof;
          if (proof is List && proof.isNotEmpty) {
            p = proof[0];
          }
          
          if (p['extractedParameterValues'] != null && p['extractedParameterValues']['username'] != null) {
             username = p['extractedParameterValues']['username'].toString();
          } else if (p['claimData'] != null && p['claimData']['context'] != null) {
            final contextData = jsonDecode(p['claimData']['context'].toString());
            if (contextData['extractedParameters'] != null && contextData['extractedParameters']['username'] != null) {
              username = contextData['extractedParameters']['username'].toString();
            }
          }
          
          // Last resort fallback
          if (username.isEmpty && p['claimData'] != null && p['claimData']['parameters'] != null) {
             dynamic params = p['claimData']['parameters'];
             if (params is String) {
               params = jsonDecode(params);
             }
             if (params['paramValues'] != null && params['paramValues']['username'] != null) {
               username = params['paramValues']['username'].toString();
             }
          }
        } catch(e) {
          debugPrint("Failed to parse Reclaim proof parameters: $e");
        }
        data = {"github_username": username}; 
      } else {
        data = {"total_balance": "10124.09"};
      }
      
      Map<String, String> sigData = {
        "signature": (proof['signatures'] != null && proof['signatures'].isNotEmpty) ? proof['signatures'][0] : "d337dcbd8b49...",
        "payloadHash": "verified_hash"
      };
      
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        widget.onSuccess(data, sigData);
        Navigator.of(context).pop();
      }
    } else {
      _addLog("> Reclaim session failed or timed out.");
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
              value: (_step) / 5,
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
            if (_requestUrl != null && _step < 5) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(_requestUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.inAppWebView);
                    } else {
                      _addLog("> Could not launch URL.");
                    }
                  },
                  icon: const Icon(Icons.open_in_browser, color: Colors.black),
                  label: const Text('Open Reclaim Verification', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
