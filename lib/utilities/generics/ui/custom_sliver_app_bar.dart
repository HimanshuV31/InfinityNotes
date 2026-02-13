import 'package:flutter/material.dart';
// import 'package:infinitynotes/services/auth/auth_service.dart';
import 'package:infinitynotes/utilities/generics/ui/animation/animation_controller.dart';
import 'package:infinitynotes/utilities/generics/ui/ui_constants.dart';
import 'package:infinitynotes/views/menu/menu_view.dart';
import 'search_bar.dart' as custom;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinitynotes/services/profile/profile_cubit.dart';
import 'package:infinitynotes/services/profile/user_profile.dart';

class CustomSliverAppBar extends StatefulWidget {
  final String? title;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? themeColor;
  final Widget? leading;
  final bool pinned;
  final bool floating;
  final double? expandedHeight;
  final Widget? flexibleSpace;
  final double elevation;
  final bool isSearchMode;
  final double? titleSpacing;
  final String userEmail;
  final bool hasNotes;
  final Function(String)? onSearchChanged;
  final VoidCallback? onToggleView;
  final bool isListView;
  final bool autoShowSearch;
  final VoidCallback? onLogout;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;

  const CustomSliverAppBar({
    super.key,
    this.title,
    this.actions,
    required this.backgroundColor,
    required this.foregroundColor,
    this.themeColor,
    this.leading,
    this.pinned = false,
    this.floating = false,
    this.expandedHeight,
    this.flexibleSpace,
    this.elevation = 0,
    this.isSearchMode = false,
    this.titleSpacing,
    required this.userEmail,
    required this.hasNotes,
    this.onSearchChanged,
    this.onToggleView,
    required this.isListView,
    this.autoShowSearch = false,
    this.onLogout,
    this.onProfile,
    this.onSettings,
  });

  @override
  State<CustomSliverAppBar> createState() => _CustomSliverAppBarState();
}

class _CustomSliverAppBarState extends State<CustomSliverAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _titleOpacity;
  late Animation<double> _searchOpacity;

  bool _showTitle = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _setupFadeAnimations();
    _checkAndPlayAnimation();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _setupFadeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _titleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    _searchOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );
  }

  void _checkAndPlayAnimation() {
    if (GlobalAnimationController.shouldShowTitleAnimation() && mounted) {
      debugPrint('Starting title animation...');

      setState(() {
        _showTitle = true;
        _isAnimating = true;
      });

      GlobalAnimationController.consumeTitleAnimation();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _fadeController.forward().then((_) {
            if (mounted) {
              setState(() {
                _showTitle = false;
                _isAnimating = false;
              });
              debugPrint('Animation complete!');
            }
          });
        }
      });
    } else {
      debugPrint('🎯 ❌ No animation - showing search directly');
      setState(() {
        _showTitle = false;
        _isAnimating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: true,
      expandedHeight: widget.expandedHeight,
      backgroundColor: Colors.transparent,
      foregroundColor: widget.foregroundColor,
      elevation: widget.elevation,
      leading: widget.leading,
      titleSpacing: 8,
      title: SizedBox(
        height: kToolbarHeight - 4,
        child: _isAnimating
            ? AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Stack(
              children: [
                Opacity(
                  opacity: _searchOpacity.value,
                  child: _buildSearchMode(),
                ),
                Opacity(
                  opacity: _titleOpacity.value,
                  child: _buildNormalMode(),
                ),
              ],
            );
          },
        )
            : _showTitle
            ? _buildNormalMode()
            : _buildSearchMode(),
      ),
      actions: widget.actions ?? [_buildProfileMenu()],
      flexibleSpace: null,
    );
  }

  Widget _buildNormalMode() {
    final theme = Theme.of(context);

    return Container(
      height: kToolbarHeight - 4,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(102),
          width: 1.2,
        ),
        boxShadow: UIConstants.containerShadow,
      ),
      alignment: Alignment.center,
      child: Text(
        widget.title ?? 'Infinity Notes',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onPrimary,
          letterSpacing: 0.5,
          shadows: UIConstants.textShadow,
        ),
      ),
    );
  }

  Widget _buildSearchMode() {
    return Container(
      height: kToolbarHeight - 4,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: custom.SearchBar(
        isExpanded: true,
        onChanged: widget.onSearchChanged,
        onToggleView: widget.onToggleView,
        isListView: widget.isListView,
        onClose: null,
      ),
    );
  }

  Widget _buildProfileMenu() {
    final profileState = context.watch<ProfileCubit>().state;
    final profile = profileState.profile;

    final displayName = profile?.fullName;
    final photoURL = profile?.photoUrl;

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MenuView(
                userEmail: widget.userEmail,
                displayName: displayName,
                photoURL: photoURL,
                onLogout: widget.onLogout,
                onProfile: widget.onProfile,
                onSettings: widget.onSettings,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.inversePrimary.withAlpha(200),
              width: 1.5,
            ),
            boxShadow: UIConstants.strongShadow,
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF3993ad),
            backgroundImage: photoURL != null && photoURL.isNotEmpty
                ? NetworkImage(photoURL)
                : null,
            child: (photoURL == null || photoURL.isEmpty)
                ? Text(
              _getInitial(displayName, widget.userEmail),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onPrimary,
                shadows: UIConstants.textShadow,
              ),
            )
                : null,
          ),
        ),
      ),
    );
  }

  String _getInitial(String? displayName, String email) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim()[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }
}
