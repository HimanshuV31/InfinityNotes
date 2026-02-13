import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:infinitynotes/services/platform/app_version.dart';
import 'package:infinitynotes/utilities/generics/ui/dialogs.dart';
import 'package:infinitynotes/services/profile/profile_cubit.dart';
import 'package:infinitynotes/utilities/navigation/about_developer_route.dart';

import '../../services/profile/user_profile.dart';

class MenuView extends StatelessWidget {
  final String userEmail;
  final String? displayName;
  final String? photoURL;
  final VoidCallback? onLogout;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;

  const MenuView({
    super.key,
    required this.userEmail,
    this.displayName,
    this.photoURL,
    this.onLogout,
    this.onProfile,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final profile = profileState.profile;

        // Priority: Firestore (ProfileCubit) -> props -> defaults
        final effectiveDisplayName = profile?.fullName ?? displayName;
        final effectivePhotoURL = profile?.photoUrl ?? photoURL;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Infinity Notes'),
            backgroundColor: theme.appBarTheme.backgroundColor,
            foregroundColor: theme.appBarTheme.foregroundColor,
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          body: ListView(
            children: [
              _buildProfileHeader(
                context,
                displayName: effectiveDisplayName,
                photoURL: effectivePhotoURL,
              ),

              // Profile
              ListTile(
                leading: Icon(
                  Icons.person,
                  color: theme.colorScheme.primary,
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

              // Settings
              ListTile(
                leading: Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Settings'),
                onTap: onSettings,
              ),

              const Divider(),

              // Logout
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: const Text('Logout'),
                onTap: onLogout,
              ),

              const SizedBox(height: 8),

              // App name + version
              ListTile(
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        'Infinity Notes',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      'Version ${AppVersion.version}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                onTap: () => openAboutDeveloper(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, {
        required String? displayName,
        required String? photoURL,
      }) {
    final theme = Theme.of(context);
    final initials = _getInitials(displayName, userEmail);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: photoURL != null && photoURL.isNotEmpty
                ? NetworkImage(photoURL)
                : null,
            child: (photoURL == null || photoURL.isEmpty)
                ? Text(
              initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3993ad),
              ),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName ?? 'User',
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
    );
  }

  String _getInitials(String? name, String email) {
    if (name != null && name.trim().isNotEmpty) {
      return name.trim()[0].toUpperCase();
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }
}
