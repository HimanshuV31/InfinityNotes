import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AIService {
  // Singleton instance
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Secure storage for API keys
  final _secureStorage = const FlutterSecureStorage();

  // Using current Gemini 2.5 models (2025)
  // static const String _openAIUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // API Keys
  String? _openAIKey;
  String? _geminiKey;

  // Conservative limits for reliability
  static const int _maxContentLength = 10000;     // Conservative for testing
  static const int _maxOutputTokens = 1000;      // Conservative output

  // Initialize API keys
  Future<void> initializeKeys({String? openAIKey, String? geminiKey}) async {
    try {
      if (openAIKey != null) {
        await _secureStorage.write(key: 'openai_key', value: openAIKey);
        _openAIKey = openAIKey;
      }
      if (geminiKey != null) {
        await _secureStorage.write(key: 'gemini_key', value: geminiKey);
        _geminiKey = geminiKey;
      }
      debugPrint("AI Service keys initialized successfully");
    } catch (e) {
      debugPrint("❌ Error initializing keys: $e");
      // Fallback to memory storage
      _geminiKey = geminiKey;
      _openAIKey = openAIKey;
    }
  }

  // Load keys from secure storage
  Future<void> _loadKeys() async {
    try {
      _openAIKey ??= await _secureStorage.read(key: 'openai_key');
      _geminiKey ??= await _secureStorage.read(key: 'gemini_key');
    } catch (e) {
      debugPrint("❌ Error loading keys from secure storage: $e");
    }
  }

  // Main summarization function
  Future<Map<String, String>> summarizeText(
      String content, {
        AIProvider provider = AIProvider.gemini,
      }) async {
    await _loadKeys();

    if (content.trim().isEmpty) {
      throw AIServiceException('Content cannot be empty');
    }

    // Simple truncation
    String processedContent = content.trim();
    if (processedContent.length > _maxContentLength) {
      processedContent = "${processedContent.substring(0, _maxContentLength)}...";
    }

    debugPrint("🔍 Processing content: ${processedContent.length} chars");

    try {
      return await _callGemini(processedContent);
    } catch (e) {
      debugPrint("❌ Gemini failed: $e");
      throw AIServiceException('Summarization failed: ${e.toString()}');
    }
  }

  // GEMINI API CALL - Using 2.5 Flash model
  Future<Map<String, String>> _callGemini(String content) async {
    if (_geminiKey == null) {
      throw AIServiceException('Gemini API key not configured');
    }

    debugPrint("🔑 Using API key: ${_geminiKey!.substring(0, 10)}...");
    debugPrint("🌐 Endpoint: $_geminiUrl");

    String prompt = '''Create a concise summary in JSON format:
      {
         "title": "Brief descriptive title (5-10 words)",
         "summary": "Clear summary covering the main points and key information"
      }
      Content: $content
      Return only valid JSON:''';

    try {
      final client = http.Client();
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': _maxOutputTokens,
          'topP': 0.8,
          'topK': 40,
        },
        'safetySettings': [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_ONLY_HIGH"
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_ONLY_HIGH"
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_ONLY_HIGH"
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_ONLY_HIGH"
          }
        ]
      };

      debugPrint("📤 Sending request...");

      final response = await client.post(
        Uri.parse('$_geminiUrl?key=$_geminiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 45));

      client.close();

      debugPrint("📡 Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        debugPrint("Success! Processing response...");

        final data = jsonDecode(response.body);

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];

          // Check finish reason
          final finishReason = candidate['finishReason'];
          debugPrint("🏁 Finish reason: $finishReason");

          if (finishReason == 'SAFETY') {
            throw AIServiceException('Content was blocked by safety filters');
          }

          String? responseText = _extractResponseText(candidate);
          if (responseText != null && responseText.trim().isNotEmpty) {
            debugPrint("📝 Response: ${responseText.substring(0, responseText.length.clamp(0, 100))}...");
            return _parseResponse(responseText);
          }
        }

        throw AIServiceException('Empty response from Gemini');

      } else {
        final errorBody = response.body;
        debugPrint("❌ Error Response: $errorBody");

        // Parse error details
        if (response.statusCode == 400) {
          if (errorBody.contains('API key')) {
            throw AIServiceException('API key is invalid or expired. Generate a new key from Google AI Studio.');
          } else if (errorBody.contains('quota') || errorBody.contains('limit')) {
            throw AIServiceException('API quota exceeded. Check your usage limits.');
          } else {
            throw AIServiceException('Bad request. Check content or API format.');
          }
        } else if (response.statusCode == 403) {
          throw AIServiceException('Access denied. Check API key permissions.');
        } else if (response.statusCode == 404) {
          throw AIServiceException('Gemini 2.5 Flash model not found. Your API key might not have access to this model.');
        } else if (response.statusCode == 429) {
          throw AIServiceException('Rate limit exceeded. Wait a moment and try again.');
        } else {
          throw AIServiceException('API Error ${response.statusCode}: $errorBody');
        }
      }
    } catch (e) {
      if (e is AIServiceException) rethrow;
      debugPrint("❌ Network error: $e");
      throw AIServiceException('Network error: ${e.toString()}');
    }
  }

  // Extract response text from API response
  String? _extractResponseText(Map<String, dynamic> candidate) {
    try {
      // Try modern content structure
      final content = candidate['content'];
      if (content != null && content['parts'] != null) {
        final parts = content['parts'] as List;
        if (parts.isNotEmpty && parts[0]['text'] != null) {
          return parts[0]['text'].toString();
        }
      }
    } catch (e) {
      debugPrint("❌ Content extraction failed: $e");
    }

    try {
      // Try legacy text field
      return candidate['text']?.toString();
    } catch (e) {
      debugPrint("❌ Legacy text extraction failed: $e");
    }

    return null;
  }

  // Parse API response into title/summary
  Map<String, String> _parseResponse(String responseText) {
    debugPrint("🔍 Parsing response...");

    try {
      // Clean response text
      String cleaned = responseText
          .replaceAll('```', '')
          .replaceAll('`', '')
          .trim();

          // Find JSON boundaries
          int start = cleaned.indexOf('{');
      int end = cleaned.lastIndexOf('}');

      if (start != -1 && end != -1 && end > start) {
        String jsonStr = cleaned.substring(start, end + 1);
        final json = jsonDecode(jsonStr);

        String title = json['title']?.toString().trim() ?? '';
        String summary = json['summary']?.toString().trim() ?? '';

        if (title.isNotEmpty && summary.isNotEmpty) {
          debugPrint("JSON parsing successful");
          return {
            'title': title.length > 100 ? '${title.substring(0, 97)}...' : title,
            'summary': summary
          };
        }
      }
    } catch (e) {
      debugPrint("❌ JSON parsing failed: $e");
    }

    // Fallback parsing
    debugPrint("🔄 Using fallback parsing");

    // Try to extract title and summary from plain text
    String cleanText = responseText.replaceAll(RegExp(r'[`*#]'), '').trim();

    // Simple fallback
    List<String> sentences = cleanText.split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    String title = 'AI Summary';
    String summary = cleanText;

    if (sentences.length > 1) {
      title = sentences.first.trim();
      if (title.length > 80) {
        title = '${title.substring(0, 77)}...';
      }
      summary = sentences.skip(1).join('. ').trim();
    }

    return {
      'title': title.isNotEmpty ? title : 'AI Summary',
      'summary': summary.isNotEmpty ? summary : 'Summary generated successfully'
    };
  }

  // Utility methods
  Future<void> clearKeys() async {
    try {
      await _secureStorage.deleteAll();
      _openAIKey = null;
      _geminiKey = null;
      debugPrint("Keys cleared");
    } catch (e) {
      debugPrint("Error clearing keys: $e");
    }
  }

  Map<String, dynamic> getServiceInfo() {
    return {
      'maxContentLength': _maxContentLength,
      'maxOutputTokens': _maxOutputTokens,
      'hasOpenAIKey': _openAIKey != null,
      'hasGeminiKey': _geminiKey != null,
      'supportedProviders': ['openAI', 'gemini'],
      'currentModel': 'gemini-2.5-flash',
    };
  }
}

// Enums and exceptions
enum AIProvider { openAI, gemini }

class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
