import 'package:flutter/material.dart';
import 'package:infinitynotes/ai_summarize/ai_service.dart';
import 'package:infinitynotes/ai_summarize/ai_summary_service.dart';
import 'package:infinitynotes/utilities/ai/ai_summary_dialog.dart';

//  Clean utility functions with no business logic
class AIHelper {
  static final AISummaryService _summaryService = AISummaryService();

  //  Simple validation helper
  static bool canSummarizeContent(String content) {
    return _summaryService.canSummarize(content);
  }

  //  Main entry point for AI summarization
  static Future<void> showSummaryDialog({
    required BuildContext context,
    required String content,
    String? title,
    AIProvider provider = AIProvider.gemini,
    VoidCallback? onSummaryCreated,
  }) async {
    if (!canSummarizeContent(content)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some content before summarizing'),
        ),
      );
      return;
    }

    return AISummaryDialog.show(
      context: context,
      content: content,
      title: title,
      provider: provider,
      onSummaryCreated: onSummaryCreated,
    );
  }

  //  Quick action helper for menu integration
  static void handleSummarizeAction({
    required BuildContext context,
    required String content,
    String? title,
    VoidCallback? onComplete,
  }) {
    showSummaryDialog(
      context: context,
      content: content,
      title: title,
      onSummaryCreated: onComplete,
    );
  }
}
