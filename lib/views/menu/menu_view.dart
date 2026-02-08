import 'package:flutter/material.dart';
import 'package:infinitynotes/services/platform/app_version.dart';
import 'package:infinitynotes/utilities/generics/ui/dialogs.dart';

class MenuView extends StatelessWidget {
  final String userEmail;
  final String? displayName;
  final String? photoURL;
  final VoidCallback? onLogout;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onReportBug;
  final VoidCallback? onFeedback;

  const MenuView({
    super.key,
    required this.userEmail,
    this.displayName,
    this.photoURL,
    this.onLogout,
    this.onProfile,
    this.onSettings,
    this.onReportBug,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Infinity Notes"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor!,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor!,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Row(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: photoURL != null && photoURL!.isNotEmpty
                      ? NetworkImage(photoURL!)
                      : null,
                  child: photoURL == null || photoURL!.isEmpty
                      ? Text(
                          displayName != null && displayName!.isNotEmpty
                              ? displayName![0].toUpperCase()
                              : userEmail[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3993ad),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName ?? "User",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          ListTile(
            leading: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Profile'),
            onTap: () {
              if (onProfile != null) {
                onProfile!();
              } else {
                showWarningDialog(
                  context: context,
                  title: 'Coming Soon',
                  message: 'Profile feature is coming soon!',
                );
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Settings'),
            onTap: onSettings,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: onLogout,
          ),

          // App Version
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child:
              Text(
              "Infinity Notes",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Text(
              'Version ${AppVersion.version}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
