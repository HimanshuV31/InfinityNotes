import 'package:flutter/material.dart';
import 'package:infinitynotes/services/platform/version_tracker.dart';
import 'package:infinitynotes/services/platform/app_version.dart';
import 'package:infinitynotes/services/platform/changelog_parser.dart';

/// Show "What's New" dialog if version changed
Future<void> showWhatsNewIfNeeded(BuildContext context) async {
  final shouldShow = await VersionTracker.shouldShowWhatsNew();

  if (shouldShow && context.mounted) {
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WhatsNewDialog(),
      );
    }
  }
}

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const WhatsNewContent(),
    );
  }
}

class WhatsNewContent extends StatefulWidget {
  const WhatsNewContent({super.key});

  @override
  State<WhatsNewContent> createState() => _WhatsNewContentState();
}

class _WhatsNewContentState extends State<WhatsNewContent> {
  VersionChangelog? _changelog;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      // Strip 'v' prefix if present
      final versionToLookup = AppVersion.version.startsWith('v')
          ? AppVersion.version.substring(1)
          : AppVersion.version;

      final changelog = await ChangelogParser.getVersionChangelog(
        versionToLookup,
      );

      if (mounted) {
        setState(() {
          _changelog = changelog;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load changelog';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _changelog == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'No changelog available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _buildActionButton(context),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            ..._buildFeatureList(context),
            const SizedBox(height: 24),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.new_releases,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "What's New in ${_changelog!.version}",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureList(BuildContext context) {
    return _changelog!.features
        .map((feature) => _buildFeatureItem(context, feature))
        .toList();
  }

  Widget _buildFeatureItem(BuildContext context, ChangelogFeature feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              feature.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (feature.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    feature.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await VersionTracker.markVersionAsSeen();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Got It!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
