import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool expands;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextAlignVertical? textAlignVertical;

  const LinkTextFormField({
    super.key,
    required this.controller,
    this.hintText,
    this.style,
    this.decoration,
    this.expands = false,
    this.maxLines,
    this.keyboardType,
    this.textAlignVertical,
  });

  @override
  State<LinkTextFormField> createState() => _LinkTextFormFieldState();
}

class _LinkTextFormFieldState extends State<LinkTextFormField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ALWAYS VISIBLE TextField with proper decoration
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          expands: widget.expands,
          textAlignVertical: widget.textAlignVertical,
          style: TextStyle(
            fontSize: 15.0,
            // Hide text when not focused, show theme color when focused
            color: _hasFocus
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
          ),
          decoration: widget.decoration ??
              InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
        ),

        // OVERLAY: RichText with colored links (only when not focused)
        if (!_hasFocus)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _focusNode.requestFocus(); // Focus TextField when tapped
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: widget.controller.text.isEmpty
                      ? Text(
                    widget.hintText ?? "Write your note here...",
                    style: TextStyle(
                      fontSize: 15.0,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  )
                      : RichText(
                    text: _buildTextSpan(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  TextSpan _buildTextSpan() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      return const TextSpan(text: '');
    }

    final spans = <TextSpan>[];
    final linkRegex = RegExp(
      r'(https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}[^\s]*)',
      caseSensitive: false,
    );

    int currentIndex = 0;
    for (final match in linkRegex.allMatches(text)) {
      // Add normal text before the link
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: TextStyle(
            fontSize: 15.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ));
      }

      // Add the clickable blue link
      final linkText = match.group(0)!;
      spans.add(TextSpan(
        text: linkText,
        style: TextStyle(
          fontSize: 15.0,
          color: Colors.blue.shade700,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blue.shade700,
        ),
        recognizer: TapGestureRecognizer()..onTap = () => _launchURL(linkText),
      ));

      currentIndex = match.end;
    }

    // Add remaining normal text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: TextStyle(
          fontSize: 15.0,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ));
    }

    return TextSpan(children: spans);
  }

  void _launchURL(String url) async {
    String processedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      processedUrl = 'https://$url';
    }

    try {
      final uri = Uri.parse(processedUrl);
      await launchUrl(uri);
      debugPrint("🔗 Launched: $uri");
    } catch (e) {
      debugPrint("🔗 Failed to launch: $e");
    }
  }
}
