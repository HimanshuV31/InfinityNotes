import 'package:flutter/material.dart';
import 'package:infinity_notes/ai_summarize/ai_service.dart';
import 'package:infinity_notes/ai_summarize/ai_summary_service.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_toast.dart';

//  Reusable UI Component with Clean Interface
class AISummaryDialog extends StatefulWidget {
  final String content;
  final String? title;
  final AIProvider provider;
  final VoidCallback? onSummaryCreated;
  final VoidCallback? onDialogClosed;

  const AISummaryDialog({
    super.key,
    required this.content,
    this.title,
    this.provider = AIProvider.gemini,
    this.onSummaryCreated,
    this.onDialogClosed,
  });

  //  Static helper method for easy usage
  static Future<void> show({
    required BuildContext context,
    required String content,
    String? title,
    AIProvider provider = AIProvider.gemini,
    VoidCallback? onSummaryCreated,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AISummaryDialog(
        content: content,
        title: title,
        provider: provider,
        onSummaryCreated: onSummaryCreated,
      ),
    );
  }

  @override
  State<AISummaryDialog> createState() => _AISummaryDialogState();
}

class _AISummaryDialogState extends State<AISummaryDialog> {
  final AISummaryService _summaryService = AISummaryService();
  bool _isLoading = false;
  AISummaryResult? _summaryResult;
  bool _summarySavedFlag = false;
  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  //  UI logic only - delegates to business logic
  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _summaryService.generateSummary(
      content: widget.content,
      title: widget.title,
      provider: widget.provider,
    );

    if (mounted) {
      setState(() {
        _summaryResult = result;
        _isLoading = false;
      });
    }
  }

  //  Save action - delegates to business logic
  Future<void> _saveSummary() async {
    if (_summaryResult == null || !_summaryResult!.isSuccess || _summarySavedFlag) return;

    try {
      _summarySavedFlag = true;
      final currentUser = AuthService.firebase().currentUser!;
      await _summaryService.saveSummaryAsNote(
        summaryResult: _summaryResult!,
        userId: currentUser.id,
      );
      if (mounted) {
        Navigator.of(context).pop();
        showCustomToast(context, "AI Summary saved successfully!");
        widget.onSummaryCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Failed to save summary: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Expanded(child: Text('AI Summary')),
          if (_summaryResult?.isSuccess == true) _buildReadyChip(),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _buildContent(),
      ),
      actions: _buildActions(),
    );
  }

  //  UI Components - Clean and focused
  Widget _buildReadyChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(77)),
      ),
      child: const Text(
        'Ready',
        style: TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Generating AI summary...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    if (_summaryResult?.isSuccess == false) {
      return _buildErrorContent();
    }

    return _buildSuccessContent();
  }

  Widget _buildErrorContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          'Failed to generate summary',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _summaryResult?.error ?? 'Unknown error',
          style: const TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    if (_summaryResult == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitlePreview(),
          const SizedBox(height: 16),
          _buildSummaryContent(),
        ],
      ),
    );
  }

  Widget _buildTitlePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview Title:',
          style: Theme.of(context)
              .textTheme
              .titleSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withAlpha(77)),
          ),
          child: Text(
            _summaryResult!.formattedTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary Content:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withAlpha(77)),
          ),
          child: Text(_summaryResult!.summary),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_isLoading) {
      return [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDialogClosed?.call();
          },
          child: const Text('Cancel'),
        ),
      ];
    }

    if (_summaryResult?.isSuccess == false) {
      return [
        TextButton(
          onPressed: _generateSummary,
          child: const Text('Retry'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDialogClosed?.call();
          },
          child: const Text('Cancel'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          widget.onDialogClosed?.call();
        },
        child: const Text('Close'),
      ),
      ElevatedButton.icon(

        onPressed: _saveSummary,
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Save as New Note'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    ];
  }
}
