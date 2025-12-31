import 'package:flutter/material.dart';
import 'package:infinity_notes/services/platform/version_tracker.dart';
import 'package:infinity_notes/services/platform/app_version.dart';

// DIALOG LOGIC - Handles showing/dismissing

/// Show "What's New" dialog if version changed
Future<void> showWhatsNewIfNeeded(BuildContext context) async {
  final shouldShow = await VersionTracker.shouldShowWhatsNew();

  if (shouldShow && context.mounted) {
    // Small delay so user sees main screen first
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

// DIALOG WIDGET - Wrapper with styling

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

// CONTENT LOGIC - What's displayed inside

class WhatsNewContent extends StatelessWidget {
  const WhatsNewContent({super.key});

  @override
  Widget build(BuildContext context) {
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

  // CONTENT SECTIONS

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
            "What's New in ${AppVersion.version}",
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
    final features = [
      _FeatureData(
        icon: Icons.bug_report_sharp,
        title: 'Bug Fixes',
        description: 'Fixed some bugs and improvements',
      ),
      _FeatureData(
        icon: Icons.palette,
        title: 'Dark & Light Themes',
        description: 'Switch between themes in Settings',
      ),
      _FeatureData(
        icon: Icons.settings,
        title: 'New Settings Screen',
        description: 'All app settings in one place',
      ),
      _FeatureData(
        icon: Icons.bug_report,
        title: 'Bug Reporting',
        description: 'Report issues from Settings',
      ),
      _FeatureData(
        icon: Icons.speed,
        title: 'Performance',
        description: 'Faster and smoother',
      ),
      _FeatureData(
        icon: Icons.animation,
        title: 'Animation',
        description: 'Smoother Animations',
      ),
    ];

    return features
        .map((feature) => _buildFeatureItem(context, feature))
        .toList();
  }

  Widget _buildFeatureItem(BuildContext context, _FeatureData data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              data.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
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

// DATA MODEL - Feature information

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
