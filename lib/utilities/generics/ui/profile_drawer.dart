import 'package:flutter/material.dart';

class ProfileDrawer extends StatelessWidget {
  final String userEmail;
  final String? userName;
  final VoidCallback onLogout;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onReportBug;
  final VoidCallback? onFeedback;


  const ProfileDrawer({
    super.key,
    required this.userEmail,
    this.userName,
    required this.onLogout,
    this.onProfile,
    this.onSettings,
    this.onReportBug,
    this.onFeedback,
  });

  String get _displayName {
    if (userName != null && userName!.isNotEmpty) {
      return userName!;
    }

    // Extract name from email
    final emailParts = userEmail.split('@');
    if (emailParts.isNotEmpty) {
      return emailParts[0].replaceAll('.', ' ').replaceAll('_', ' ').split(' ')
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }

    return 'User';
  }

  String get _initials {
    final words = _displayName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.45;

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(102), // Dark overlay
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topRight, //  Align to top right
            child: Container(
              width: drawerWidth,
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 60, // Below AppBar
                right: 8, // Small margin from edge
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(-2, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, //  Only take needed space
                children: [
                  // Header section with profile
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF3993ad),
                          Color(0xFF2980b9),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Profile picture
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40), //  Increased from 20 to 40
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha(153), //  Increased from 30 to 60
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, //  Full opacity white
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // User name
                        Text(
                          _displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white, //  Full opacity white
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // User email
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withAlpha(180),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Menu options
                  _buildMenuTile(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onProfile != null) onProfile!();
                    },
                  ),

                  _buildMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onSettings != null) onSettings!();
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.feedback_outlined,
                    title: 'Send Feedback',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onFeedback != null) onFeedback!();
                    },
                  ),
                  _buildMenuTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Report Bug',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onReportBug != null) onReportBug!();
                    },
                    isDestructive: true,
                  ),
                  const Divider(
                    color: Colors.white24,
                    thickness: 1,
                    height: 24,
                    indent: 16,
                    endIndent: 16,
                  ),

                  _buildMenuTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      Navigator.of(context).pop();
                      onLogout();
                    },
                    isDestructive: true,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? Colors.redAccent.withAlpha(200) //  Increased from 80 to 200 (~78% opacity)
                    : Colors.white.withAlpha(220),     //  Increased from 80 to 220 (~86% opacity)
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? Colors.redAccent.withAlpha(200) //  Increased from 80 to 200
                      : Colors.white.withAlpha(230),     //  Increased from 90 to 230 (~90% opacity)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  SIMPLE: Direct dialog approach (unchanged)
void showProfileDrawer({
  required BuildContext context,
  required String userEmail,
  String? userName,
  required VoidCallback onLogout,
  VoidCallback? onProfile,
  VoidCallback? onSettings,
  VoidCallback? onReportBug,
  VoidCallback? onFeedback,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return ProfileDrawer(
        userEmail: userEmail,
        userName: userName,
        onLogout: onLogout,
        onProfile: onProfile,
        onSettings: onSettings,
        onReportBug: onReportBug,
        onFeedback: onFeedback,
      );
    },
  );
}
