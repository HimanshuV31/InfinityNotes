import 'package:infinitynotes/ai_summarize/ai_service.dart';
import 'package:infinitynotes/services/cloud/cloud_note.dart';
import 'package:infinitynotes/services/cloud/firebase_cloud_storage.dart';

class AISummaryService {
  static final AISummaryService _instance = AISummaryService._internal();
  factory AISummaryService() => _instance;
  AISummaryService._internal();

  final AIService _aiService = AIService();
  final FirebaseCloudStorage _cloudStorage = FirebaseCloudStorage();

  //  Core business logic for generating summaries
  Future<AISummaryResult> generateSummary({
    required String content,
    String? title,
    AIProvider provider = AIProvider.gemini,
  }) async {
    try {
      if (content.trim().isEmpty) {
        throw AISummaryException('Content cannot be empty');
      }
      final summaryData = await _aiService.summarizeText(content, provider: provider);
      return AISummaryResult(
        originalTitle: title ?? 'Untitled',
        aiGeneratedTitle: summaryData['title'] ?? 'Untitled Summary',
        summary: summaryData['summary'] ?? 'Summary not available',
        isSuccess: true,
      );
    } catch (e) {
      return AISummaryResult(
        originalTitle: title ?? 'Untitled',
        aiGeneratedTitle: '',
        summary: '',
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  //  Business logic for saving AI summaries with proper formatting
  Future<CloudNote> saveSummaryAsNote({
    required AISummaryResult summaryResult,
    required String userId,
  }) async {
    if (!summaryResult.isSuccess) {
      throw AISummaryException('Cannot save failed summary');
    }

    //  Apply [AI Summary] formatting here
    final formattedTitle = "[AI Summary] ${summaryResult.aiGeneratedTitle}";

    final savedNote = await _cloudStorage.createNewNote(
      ownerUserId: userId,
      title: formattedTitle,
      text: summaryResult.summary,
    );

    return savedNote;
  }

  //  Validation logic
  bool canSummarize(String content) {
    return content.trim().isNotEmpty;
  }

  //  Create temporary CloudNote for processing
  CloudNote createTempNote({
    required String title,
    required String content,
    required String userId,
    List<String>? links,
  }) {
    final now = DateTime.now();
    return CloudNote(
      documentId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      ownerUserId: userId,
      title: title.isNotEmpty ? title : 'Untitled Note',
      text: content,
      links: links ?? [],
      createdAt: now, //  ADD: Current timestamp
      updatedAt: now, //  ADD: Current timestamp
    );
  }
}

//  Data models for clean data transfer
class AISummaryResult {
  final String originalTitle;
  final String aiGeneratedTitle;
  final String summary;
  final bool isSuccess;
  final String? error;

  AISummaryResult({
    required this.originalTitle,
    required this.aiGeneratedTitle,
    required this.summary,
    required this.isSuccess,
    this.error,
  });

  //  Computed property for formatted title
  String get formattedTitle => "[AI Summary] $aiGeneratedTitle";
}

class AISummaryException implements Exception {
  final String message;
  AISummaryException(this.message);

  @override
  String toString() => 'AISummaryException: $message';
}
