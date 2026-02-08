import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Represents a single feature in changelog
class ChangelogFeature {
  final IconData icon;
  final String title;
  final String description;

  const ChangelogFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Represents a version's changelog
class VersionChangelog {
  final String version;
  final List<ChangelogFeature> features;

  const VersionChangelog({
    required this.version,
    required this.features,
  });
}

class ChangelogParser {
  /// Get changelog for specific version
  static Future<VersionChangelog?> getVersionChangelog(String version) async {
    try {
      final markdown = await rootBundle.loadString(
        'assets/changelogs/CHANGELOG.md',
      );
      final allChangelogs = _parseMarkdown(markdown);
      return allChangelogs[version];
    } catch (e) {
      debugPrint('Failed to load changelog: $e');
      return null;
    }
  }

  /// Parse markdown content into structured data
  static Map<String, VersionChangelog> _parseMarkdown(String markdown) {
    final changelogs = <String, VersionChangelog>{};
    final versionBlocks = markdown.split(RegExp(r'\n#\s+'));

    for (final block in versionBlocks) {
      if (block.trim().isEmpty) continue;

      final lines = block.split('\n');
      final version = lines.first.trim();

      // Skip non-version headers
      if (!RegExp(r'^\d+\.\d+\.\d+').hasMatch(version)) continue;

      final features = <ChangelogFeature>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();

        if (line.isEmpty || line.startsWith('---')) continue;

        // Parse feature line: [icon:name] **Title**
        if (line.startsWith('[icon:')) {
          final iconMatch = RegExp(r'\[icon:(.*?)\]').firstMatch(line);
          final titleMatch = RegExp(r'\*\*(.*?)\*\*').firstMatch(line);

          if (iconMatch != null && titleMatch != null) {
            final iconName = iconMatch.group(1)!;
            final title = titleMatch.group(1)!;

            // Get description from next line
            String description = '';
            if (i + 1 < lines.length) {
              final nextLine = lines[i + 1].trim();
              if (nextLine.isNotEmpty && !nextLine.startsWith('[icon:')) {
                description = nextLine;
                i++;
              }
            }

            features.add(ChangelogFeature(
              icon: _getIconData(iconName),
              title: title,
              description: description,
            ));
          }
        }
      }

      if (features.isNotEmpty) {
        changelogs[version] = VersionChangelog(
          version: version,
          features: features,
        );
      }
    }

    return changelogs;
  }

  /// Map icon names to Material IconData
  static IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'bug_report':
      case 'bug_report_sharp':
        return Icons.bug_report_sharp;
      case 'palette':
        return Icons.palette;
      case 'settings':
        return Icons.settings;
      case 'speed':
        return Icons.speed;
      case 'animation':
        return Icons.animation;
      case 'cloud':
      case 'cloud_sync':
        return Icons.cloud_sync;
      case 'security':
      case 'lock':
        return Icons.lock;
      case 'note_add':
      case 'edit_note':
        return Icons.note_add;
      case 'search':
        return Icons.search;
      case 'folder':
      case 'category':
        return Icons.folder;
      case 'share':
        return Icons.share;
      case 'feedback':
        return Icons.feedback;
      case 'notifications':
      case 'push_pin':
        return Icons.push_pin;
      case 'dark_mode':
        return Icons.dark_mode;
      case 'light_mode':
        return Icons.light_mode;
      case 'checklist':
      case 'task_alt':
        return Icons.checklist;
      case 'mic':
      case 'record_voice_over':
        return Icons.mic;
      case 'image':
      case 'photo':
        return Icons.image;
      case 'edit':
      case 'create':
        return Icons.edit;
      case 'save':
      case 'save_alt':
        return Icons.save;
      case 'grid_view':
        return Icons.grid_view;
      case 'view_list':
        return Icons.view_list;
      case 'tune':
        return Icons.tune;
      case 'color_lens':
        return Icons.color_lens;
      case 'backup':
        return Icons.backup;
      default:
        return Icons.info;
    }
  }
}
