import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LlmService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // Fallback to a placeholder if .env is not present for safety, 
    // but typically you should put GEMINI_API_KEY=your_key in .env
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_API_KEY';
    
    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''
You are the PrivatePilot AI intent parser for the Veil app.
You must act as a blind router. You will receive user text.
You must output ONLY valid JSON.
Valid intents:
{"intent": "CHECK_ELIGIBILITY", "target": "string"}
{"intent": "FIND_ELIGIBLE_PROGRAMS"}
{"intent": "CHECK_BALANCE"}
{"intent": "GENERATE_PROOF", "target": "string"}
{"intent": "CONVERSATION", "message": "string"}

For CHECK_ELIGIBILITY, "target" should be the name of the grant/scholarship (e.g., "starter_grant"). Use this anytime the user asks if they qualify or are eligible for a specific program.
For FIND_ELIGIBLE_PROGRAMS, use this when the user asks what programs they are eligible for in general.
For GENERATE_PROOF, "target" should be the program name.
For CONVERSATION, "message" should contain a helpful reply to the user.

CRITICAL INSTRUCTION: You are a BLIND ROUTER. You do not have access to the user's private data (like wallet balance or GitHub PRs). NEVER try to answer eligibility questions or balance questions yourself in a CONVERSATION intent. ALWAYS route them to CHECK_ELIGIBILITY, FIND_ELIGIBLE_PROGRAMS, or CHECK_BALANCE so the local app can process them securely.
'''),
    );
    _isInitialized = true;
  }

  Future<Map<String, dynamic>> parseIntent(String userText) async {
    try {
      final content = [Content.text(userText)];
      final response = await _model.generateContent(content);
      String responseText = response.text?.trim() ?? '';
      
      // Clean up markdown block if present
      if (responseText.startsWith('```json')) {
        responseText = responseText.substring(7);
      } else if (responseText.startsWith('```')) {
        responseText = responseText.substring(3);
      }
      if (responseText.endsWith('```')) {
        responseText = responseText.substring(0, responseText.length - 3);
      }
      
      return jsonDecode(responseText.trim());
    } catch (e) {
      print('LLM Service Error: $e');
      return {
        "intent": "CONVERSATION",
        "message": "I'm having trouble processing that securely right now. Please try again."
      };
    }
  }
}
