import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class AboutDeveloperView extends StatefulWidget {
  const AboutDeveloperView({super.key});

  @override
  State<AboutDeveloperView> createState() => _AboutDeveloperViewState();
}

class _AboutDeveloperViewState extends State<AboutDeveloperView> {
  String? _markdown;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    try {
      final text =
      await rootBundle.loadString('assets/about/about_developer.md');
      if (!mounted) return;
      setState(() {
        _markdown = text;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _markdown = '# About the Developer\n\nFailed to load content.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About the Developer'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Markdown(
        data: _markdown ?? '',
        styleSheet: MarkdownStyleSheet.fromTheme(theme),
      ),
    );
  }
}
