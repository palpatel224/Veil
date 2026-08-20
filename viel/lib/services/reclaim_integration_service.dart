import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:reclaim_sdk/reclaim.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_service.dart';

class ReclaimIntegrationService {
  // TODO: Replace these with your actual keys from the Reclaim Developer Portal (https://dev.reclaimprotocol.org/)
  static const String _appId = '0x3e383c569c9A6B7f75328E91529EB35Bf721EFf0';
  static const String _appSecret = '0xa94f0b6e4628c0aad00679a79853b243a8f243309271bfc79671939a28d8eb8f';
  
  // The official Reclaim Provider ID for GitHub Pull Requests / Commits
  static const String _githubProviderId = '6d3f6753-7ee6-49ee-a545-62f1b1822ce5';

  static Future<void> connectGitHub(BuildContext context, DatabaseService db, VoidCallback onComplete) async {
    try {
      // 1. Initialize the Reclaim Proof Request using the static init method
      // This automatically generates the signature and builds the request
      final proofRequest = await ReclaimProofRequest.init(
        _appId,
        _appSecret,
        _githubProviderId,
      );
      
      // 2. Get the unique URL for this zkTLS session and launch it
      final requestUrl = await proofRequest.getRequestUrl();
      final uri = Uri.parse(requestUrl);
      
      if (await canLaunchUrl(uri)) {
        // Open the secure browser where the user logs into GitHub
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } else {
        throw 'Could not launch $requestUrl';
      }

      // 3. Start the session which polls for completion
      await proofRequest.startSession(
        onSuccess: (dynamic proofInput) async {
          // The zkTLS flow succeeded! The Reclaim Node has intercepted and signed the GitHub data.
          
          // Depending on the request, proof might be a list or a single object. 
          // We assume single object (or first object) here, but handle both.
          dynamic proof = (proofInput is List && proofInput.isNotEmpty) ? proofInput.first : proofInput;
          
          // Try to decode extracted parameter values (if it's a map or a json string)
          Map<String, dynamic> extractedData = {};
          if (proof.claimData != null && proof.claimData.context != null) {
            final contextStr = proof.claimData.context.toString();
            try {
              final ctxJson = jsonDecode(contextStr);
              if (ctxJson['extractedParameters'] != null) {
                 extractedData = ctxJson['extractedParameters'] is String 
                    ? jsonDecode(ctxJson['extractedParameters']) 
                    : ctxJson['extractedParameters'];
              }
            } catch (e) {
              debugPrint('Could not parse extracted params context: $e');
            }
          }
          
          final prCount = extractedData['prs'] ?? extractedData['commits'] ?? '0';

          // Extract the Reclaim Node's cryptographic signature
          final signature = (proof.signatures != null && proof.signatures.isNotEmpty) ? proof.signatures.first : '';
          
          // Save the verified data and its signature to the local SQLite Secure Enclave
          await db.updateMetric('github_prs', prCount.toString(), 'github_zktls');
          await db.updateMetric('github_signature', signature, 'zktls_signature');
          
          // We also save the hash of the payload to pass into the Noir circuit later
          final payloadHash = proof.identifier ?? '';
          await db.updateMetric('github_hash', payloadHash, 'zktls_hash');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('GitHub Connected successfully via real zkTLS!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          onComplete();
        },
        onError: (Exception error) {
          debugPrint('Reclaim zkTLS Error: $error');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to connect GitHub: $error'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          onComplete();
        }
      );

    } catch (e) {
      debugPrint('Reclaim SDK Setup Error: $e');
      onComplete();
    }
  }
}
