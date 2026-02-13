import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinitynotes/services/theme/theme_notifier.dart';
import 'package:infinitynotes/services/platform/app_version.dart';
import 'package:infinitynotes/utilities/generics/ui/feedback_dialog.dart';
import 'package:infinitynotes/utilities/navigation/about_developer_route.dart';

class SettingsView extends StatelessWidget {
  final String userEmail;
  const SettingsView({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeSelector(context),

          const Divider(),

          // Feedback & Support Section
          _buildSectionHeader(context, 'Feedback & Support'),
          _buildMenuItem(
            icon: Icons.bug_report,
            title: 'Report a Bug',
            onTap: () => _showBugReport(context),
          ),
          _buildMenuItem(
            icon: Icons.feedback,
            title: 'Send Feedback',
            onTap: () => _showFeedback(context),
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildMenuItem(
            icon: Icons.developer_mode,
            title: 'About the Developer',
            onTap: ()=>openAboutDeveloper(context),
            // subtitle: AppVersion.version,
            trailing: const SizedBox.shrink(),
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: AppVersion.version,
            trailing: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme'),
          subtitle: Text(_getThemeLabel(themeNotifier.themeMode)),
          trailing: DropdownButton<ThemeMode>(
            value: themeNotifier.themeMode,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark'),
              ),
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System'),
              ),
            ],
            onChanged: (mode) {
              if (mode != null) {
                themeNotifier.setTheme(mode);
              }
            },
          ),
        );
      },
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'Follow system';
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showBugReport(BuildContext context) {
    showFeedbackDialog(
      context: context,
      type: FeedbackType.bugReport,
      userEmail: userEmail,
    );
  }

  void _showFeedback(BuildContext context) {
    showFeedbackDialog(
      context: context,
      type: FeedbackType.generalFeedback,
      userEmail: userEmail,
    );
  }
}
