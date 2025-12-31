import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  ApiKeys._(); // Private constructor

  /// Gemini API Key loaded from .env file
  static String get geminiAPIKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// OpenAI API Key (not used, but available for future)
  static String get openAIAPIKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  /// Check if keys are configured
  static bool get areKeysConfigured {
    return geminiAPIKey.isNotEmpty;
  }
}
