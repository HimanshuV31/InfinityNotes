import 'package:flutter/material.dart';
import 'package:infinity_notes/services/feedback/emailjs_feedback_service.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_toast.dart';

enum FeedbackType {
  bugReport,
  generalFeedback,
}

// Reusable dialog for collecting user feedback or bug reports
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userInput = _textController.text.trim();

      final success = await EmailJSFeedbackService.sendFeedback(
        userEmail: widget.userEmail,
        userName: widget.userEmail.split('@')[0],
        message: userInput,
        type: widget.type == FeedbackType.bugReport
            ? EmailJSFeedbackType.bugReport
            : EmailJSFeedbackType.generalFeedback,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

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
    return Dialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  Icon(
                    widget.type == FeedbackType.bugReport
                        ? Icons.bug_report_outlined
                        : Icons.feedback_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dialogTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // FORM CONTENT
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User email display (read-only)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(13),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(26),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color:
                            Theme.of(context).textTheme.bodySmall?.color,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.userEmail,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Text input
                    TextFormField(
                      controller: _textController,
                      autofocus: true,
                      maxLines: 5,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: _hintText,
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withAlpha(102),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(26),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(26),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
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
                          color: Colors.blue.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withAlpha(77),
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

              const SizedBox(height: 24),

              // ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _isSubmitting
                            ? Theme.of(context).disabledColor
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor:
                      Theme.of(context).colorScheme.onPrimary,
                      disabledBackgroundColor: Theme.of(context).disabledColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
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
              ),
            ],
          ),
        ),
      ),
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
