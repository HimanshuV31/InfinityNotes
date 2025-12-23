import 'package:flutter/material.dart';

typedef DialogOptionBuilder<T> = Map<String, DialogOption<T>> Function(
    BuildContext context);

class DialogOption<T> {
  final T? value;
  final ButtonStyle? style;
  final Color? textColor;
  final VoidCallback? onPressed;

  DialogOption({this.value, this.style, this.textColor, this.onPressed});
}

// Generic Dialog
Future<T?> _showGenericDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required DialogOptionBuilder<T> optionBuilder,
  bool? barrierDismissible,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible ?? true,
    builder: (dialogContext) {
      final options = optionBuilder(dialogContext);
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: options.entries.map((entry) {
          final optionTitle = entry.key;
          final optionDataMessage = entry.value;
          final optionTextColor = entry.value.textColor;
          return ElevatedButton(
            style: optionDataMessage.style ??
                TextButton.styleFrom(
                  backgroundColor:
                  Theme.of(dialogContext).colorScheme.primary,
                ),
            onPressed: () {
              if (optionDataMessage.onPressed != null) {
                Navigator.of(dialogContext).pop();
                optionDataMessage.onPressed!();
              } else {
                Navigator.of(dialogContext).pop(optionDataMessage.value);
              }
            },
            child: Text(
              optionTitle,
              style: TextStyle(
                color: optionTextColor ??
                    Theme.of(dialogContext).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

// Delete Dialog
Future<bool> showDeleteDialog({required BuildContext context}) {
  return _showGenericDialog<bool>(
    context: context,
    title: 'Delete',
    content: 'Are you sure you want to delete this item?',
    optionBuilder: (ctx) => {
      'Cancel': DialogOption<bool>(
        value: false,
        style: TextButton.styleFrom(
          backgroundColor: Colors.red,
        ),
      ),
      'Delete': DialogOption<bool>(
        value: true,
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(ctx).colorScheme.primary,
        ),
        textColor: Colors.red,
      ),
    },
  ).then((value) => value ?? false);
}

// Warning Dialog
Future<bool?> showWarningDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = "OK",
}) {
  return _showGenericDialog<bool>(
    context: context,
    title: title,
    content: message,
    barrierDismissible: false,
    optionBuilder: (ctx) => {
      buttonText: DialogOption<bool>(value: true),
    },
  );
}

// Logout Dialog
Future<bool> showLogoutDialog({required BuildContext context}) {
  return _showGenericDialog<bool>(
    context: context,
    title: "Logout",
    content: "Are you sure you want to logout?",
    optionBuilder: (ctx) => {
      "Cancel": DialogOption<bool>(
        value: false,
        style: TextButton.styleFrom(backgroundColor: Colors.red),
      ),
      "Logout": DialogOption<bool>(
        value: true,
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(ctx).colorScheme.primary,
        ),
        textColor: Colors.red,
      ),
    },
  ).then((value) => value ?? false);
}

// Can't share empty Notes
Future<void> showCannotShareEmptyNoteDialog(BuildContext context) {
  return _showGenericDialog<void>(
    context: context,
    title: "Can't Share Empty Notes",
    content:
    'Error while sharing an empty note. Please select a non-empty note to share.',
    optionBuilder: (ctx) => {
      "OK": DialogOption<void>(value: null),
    },
  );
}

// Custom Routing Dialog
Future<void> showCustomRoutingDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String routeButtonText,
  required VoidCallback onRoutePressed,
  String? cancelButtonText,
  ButtonStyle? cancelButtonStyle,
  ButtonStyle? routeButtonStyle,
  bool? barrierDismissible,
}) {
  return _showGenericDialog<void>(
    context: context,
    title: title,
    content: content,
    barrierDismissible: barrierDismissible ?? true,
    optionBuilder: (ctx) => {
      if (cancelButtonText != null)
        cancelButtonText: DialogOption<void>(
          value: null,
          style: cancelButtonStyle ??
              TextButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      routeButtonText: DialogOption<void>(
        value: null,
        style: routeButtonStyle ??
            TextButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
            ),
        onPressed: () => {
          Navigator.of(ctx).pop(),
          onRoutePressed(),
        },
      ),
    },
  );
}

// Loading Dialog
typedef CloseDialog = void Function();

CloseDialog showLoadingDialog({
  required BuildContext context,
  required String text,
}) {
  final dialog = AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(text),
      ],
    ),
  );
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => dialog,
  );
  return () => Navigator.of(context).pop();
}

// Confirm Dialog
Future<bool> showConfirmDialog({required BuildContext context}) {
  return _showGenericDialog<bool>(
    context: context,
    barrierDismissible: false,
    title: 'Send Password Reset Email',
    content: 'Are you sure you want to send a password reset email?',
    optionBuilder: (ctx) => {
      'CANCEL': DialogOption<bool>(
        value: false,
        style: TextButton.styleFrom(
          backgroundColor: Colors.red,
        ),
      ),
      'CONFIRM': DialogOption<bool>(
        value: true,
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(ctx).colorScheme.primary,
        ),
        textColor: Theme.of(ctx).colorScheme.onPrimary,
      ),
    },
  ).then((value) => value ?? false);
}
