import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:reclaim_sdk/reclaim_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_service.dart';

class ReclaimIntegrationService {
  // TODO: Replace these with your actual keys from the Reclaim Developer Portal (https://dev.reclaimprotocol.org/)
  static const String _appId = 'YOUR_RECLAIM_APP_ID';
  static const String _appSecret = 'YOUR_RECLAIM_APP_SECRET';
  
  // The official Reclaim Provider ID for GitHub Pull Requests / Commits
  static const String _githubProviderId = '6d3f6753-7ee6-49ee-a545-62f1b1822ce5';

  static Future<void> connectGitHub(BuildContext context, DatabaseService db, VoidCallback onComplete) async {
    try {
      // 1. Initialize the Reclaim Proof Request
      final proofRequest = ReclaimProofRequest(applicationId: _appId);
      
      // 2. Build the request for the specific GitHub Provider
      await proofRequest.buildProofRequest(_githubProviderId);
      
      // 3. Set the App Secret to sign the request (Note: In production, do this on a backend!)
      proofRequest.setSignature(_appSecret);

      // 4. Set up callbacks for when the user completes the zkTLS flow in the browser
      proofRequest.onSuccess((Proof proof) async {
        // The zkTLS flow succeeded! The Reclaim Node has intercepted and signed the GitHub data.
        
        // Extract the verified data (e.g., number of PRs) from the proof
        final extractedData = jsonDecode(proof.extractedParameterValues ?? '{}');
        final prCount = extractedData['prs'] ?? extractedData['commits'] ?? '0';

        // Extract the Reclaim Node's cryptographic signature
        final signature = proof.signatures.isNotEmpty ? proof.signatures.first : '';
        
        // Save the verified data and its signature to the local SQLite Secure Enclave
        await db.updateMetric('github_prs', prCount.toString(), 'github_zktls');
        await db.updateMetric('github_signature', signature, 'zktls_signature');
        
        // We also save the hash of the payload to pass into the Noir circuit later
        // (Reclaim provides the claimInfo hash which the signature verifies)
        final payloadHash = proof.claimInfo?.hash ?? '';
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
      });

      proofRequest.onFailure((Exception error) {
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
      });

      // 5. Get the unique URL for this zkTLS session and launch it
      final requestUrl = await proofRequest.getRequestUrl();
      final uri = Uri.parse(requestUrl);
      
      if (await canLaunchUrl(uri)) {
        // Open the secure browser where the user logs into GitHub
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } else {
        throw 'Could not launch $requestUrl';
      }

    } catch (e) {
      debugPrint('Reclaim SDK Setup Error: $e');
      onComplete();
    }
  }
}
