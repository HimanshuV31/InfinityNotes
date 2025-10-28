import 'package:flutter/material.dart';
import 'package:infinity_notes/services/feedback/emailjs_feedback_service.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_toast.dart';

enum FeedbackType {
  bugReport,
  generalFeedback,
}

/// Reusable dialog for collecting user feedback or bug reports
class FeedbackDialog extends StatefulWidget {
  final FeedbackType type;
  final String userEmail;

  const FeedbackDialog({
    super.key,
    required this.type,
    required this.userEmail,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  bool _isSubmitting = false;

  String get _dialogTitle {
    return widget.type == FeedbackType.bugReport
        ? 'Report a Bug'
        : 'Send Feedback';
  }

  String get _hintText {
    return widget.type == FeedbackType.bugReport
        ? 'Describe the bug:\n• What happened?\n• What did you expect?\n• Steps to reproduce?'
        : 'Share your thoughts, suggestions, or feature requests...';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userInput = _textController.text.trim();

      // ✅ NEW: Use EmailJS service
      final success = await EmailJSFeedbackService.sendFeedback(
        userEmail: widget.userEmail,
        userName: widget.userEmail.split('@')[0], // Extract name from email
        message: userInput,
        type: widget.type == FeedbackType.bugReport
            ? EmailJSFeedbackType.bugReport
            : EmailJSFeedbackType.generalFeedback,
      );

      if (!mounted) return;

      Navigator.of(context).pop(); // Close dialog

      if (success) {
        showCustomToast(
          context,
          '✅ Feedback sent! We\'ll respond within 24 hours.',
        );
      } else {
        showCustomToast(
          context,
          '❌ Failed to send feedback. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      showCustomToast(
        context,
        'Error: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            widget.type == FeedbackType.bugReport
                ? Icons.bug_report_outlined
                : Icons.feedback_outlined,
            color: const Color(0xFF3993ad),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _dialogTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User email display (read-only)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.userEmail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Multi-line text input
              TextFormField(
                controller: _textController,
                autofocus: true,
                maxLines: 8,
                minLines: 6,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: _hintText,
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3993ad),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some details';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more details (min 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Device info note
              if (widget.type == FeedbackType.bugReport)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade300,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Device info will be attached automatically',
                          style: TextStyle(
                            color: Colors.blue.shade200,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: _isSubmitting ? Colors.grey : Colors.white70,
              fontSize: 15,
            ),
          ),
        ),

        // Submit button
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3993ad),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : const Text(
            'Send',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper function to show feedback dialog
Future<void> showFeedbackDialog({
  required BuildContext context,
  required FeedbackType type,
  required String userEmail,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => FeedbackDialog(
      type: type,
      userEmail: userEmail,
    ),
  );
}
