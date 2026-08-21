import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class ProofService {
  static InAppLocalhostServer? _localhostServer;
  static HeadlessInAppWebView? _headlessWebView;
  static Completer<void>? _webViewReadyCompleter;

  static Future<void> initProver() async {
    if (_localhostServer == null) {
      _localhostServer = InAppLocalhostServer(documentRoot: 'assets/prover', port: 8080);
      await _localhostServer?.start();
    }

    if (_headlessWebView == null) {
      _webViewReadyCompleter = Completer<void>();
      
      _headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri("http://localhost:8080/index.html")),
        onWebViewCreated: (controller) {
          debugPrint("HeadlessInAppWebView created");
        },
        onLoadStop: (controller, url) async {
          debugPrint("HeadlessInAppWebView loaded: $url");
          if (_webViewReadyCompleter != null && !_webViewReadyCompleter!.isCompleted) {
            _webViewReadyCompleter?.complete();
          }
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint("Prover JS: ${consoleMessage.message}");
        },
      );

      await _headlessWebView?.run();
      await _webViewReadyCompleter?.future;
    }
  }

  static Future<void> disposeProver() async {
    if (_headlessWebView != null) {
      await _headlessWebView?.dispose();
      _headlessWebView = null;
    }
    if (_localhostServer != null) {
      await _localhostServer?.close();
      _localhostServer = null;
    }
  }

  static Future<String?> buildReclaimRequest(String providerId, String appId, String appSecret) async {
    await initProver();
    final scriptBody = """
        try {
          var res = await window.VeilProver.buildReclaimRequest('$providerId', '$appId', '$appSecret');
          return res;
        } catch(e) {
          return JSON.stringify({success: false, error: e.toString()});
        }
    """;
    final asyncResult = await _headlessWebView!.webViewController?.callAsyncJavaScript(functionBody: scriptBody);
    if (asyncResult != null && asyncResult.value != null) {
       final resStr = asyncResult.value as String;
       final resMap = jsonDecode(resStr);
       if (resMap['success'] == true) {
         return resMap['requestUrl'];
       } else {
         debugPrint("Reclaim build request error: ${resMap['error']}");
       }
    }
    return null;
  }

  static Future<dynamic> startReclaimSession() async {
    final scriptBody = """
        try {
          var res = await window.VeilProver.startReclaimSession();
          return res;
        } catch(e) {
          return JSON.stringify({success: false, error: e.toString()});
        }
    """;
    final asyncResult = await _headlessWebView!.webViewController?.callAsyncJavaScript(functionBody: scriptBody);
    if (asyncResult != null && asyncResult.value != null) {
       final resStr = asyncResult.value as String;
       final resMap = jsonDecode(resStr);
       if (resMap['success'] == true) {
         return resMap['proof'];
       } else {
         debugPrint("Reclaim session error: ${resMap['error']}");
       }
    }
    return null;
  }


  /// Generates a Zero-Knowledge Proof for the Veil Universal Circuit via WASM JS bridge.
  static Future<Map<String, dynamic>> generateProof({
    required double minBalance,
    required int minPrs,
    Function(String)? onStatus,
  }) async {
    try {
      if (onStatus != null) onStatus("Fetching secure enclave data...");

      // 1. Fetch user data from secure local storage
      final db = DatabaseService();
      final balanceStr = await db.getMetric('total_balance') ?? '0';
      final prsStr = await db.getMetric('github_prs') ?? '0';

      final userBalance = double.tryParse(balanceStr) ?? 0.0;
      final userPrs = int.tryParse(prsStr) ?? 0;

      // Ensure prover is initialized
      if (onStatus != null) onStatus("Initializing ZK engine...");
      await initProver();

      // Normalize inputs for the ML model (matching 1_train_export.py structure)
      // Feature 0: Normalized Monthly Spending (dummy mapped from balance for now, assuming balance < 40000 -> eligible)
      // We will map userBalance to feature 0 as userBalance / 100000
      double feature0 = userBalance / 100000.0;
      double feature1 = 0.05; // Dummy for avg transaction
      double feature2 = userPrs / 100.0; // Normalized PRs
      double feature3 = 0.60; // Dummy monthly income
      
      final inputDataObj = {
        "input_data": [[feature0, feature1, feature2, feature3]]
      };

      if (onStatus != null) onStatus("Running SNARK prover (EZKL WASM)...");
      final inputJson = jsonEncode(inputDataObj);

      final scriptBody = """
          try {
            await window.VeilProver.init();
            var inputObj = $inputJson;
            var proof = await window.VeilProver.generateProofFromUrls(inputObj);
            return JSON.stringify({success: true, proof: proof});
          } catch(e) {
            return JSON.stringify({success: false, error: e.toString()});
          }
      """;
      final asyncResult = await _headlessWebView!.webViewController?.callAsyncJavaScript(functionBody: scriptBody);
      final resultStr = asyncResult?.value is String ? asyncResult!.value : '{"success":false, "error":"Failed to call JS"}';

      final result = jsonDecode(resultStr);

      if (result['success'] == true) {
        final proofObj = result['proof'];
        
        List<String> formattedInstances = [];
        if (proofObj['instances'] is List) {
          for (var col in proofObj['instances']) {
            if (col is List) {
              for (var val in col) {
                String hexStr = val.toString();
                if (hexStr.startsWith('0x')) {
                  hexStr = hexStr.substring(2);
                }
                if (hexStr.length % 2 != 0) {
                  hexStr = '0$hexStr';
                }
                
                String reversedHex = '';
                for (int i = 0; i < hexStr.length; i += 2) {
                  reversedHex = hexStr.substring(i, i + 2) + reversedHex;
                }
                formattedInstances.add(reversedHex);
              }
            }
          }
        }

        return {
          'success': true,
          'proof': proofObj['hex_proof'],
          'publicInputs': formattedInstances,
          'actualStatsUsed': {
            'balance': userBalance,
            'prs': userPrs,
          },
        };
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'Unknown error in ZK generation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      // Ensure the heavy WASM WebView is always cleaned up after proof generation
      await disposeProver();
    }
  }
}
