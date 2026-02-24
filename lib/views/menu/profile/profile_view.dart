import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:infinitynotes/services/profile/user_profile.dart';
import 'package:infinitynotes/services/profile/user_profile_service.dart';
import 'package:infinitynotes/utilities/generics/ui/dialogs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinitynotes/services/profile/profile_cubit.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final UserProfileService _service;

  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _dobController       = TextEditingController();
  String? _gender;

  UserProfile? _originalProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = UserProfileService(
      firestore: FirebaseFirestore.instance,
      firebaseAuth: FirebaseAuth.instance,
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _service.loadProfile();
      _originalProfile = profile;

      _firstNameController.text = profile.firstName;
      _lastNameController.text  = profile.lastName ?? '';
      if (profile.dob != null && profile.dob!.isNotEmpty) {
        try {
          // assuming stored as yyyy-MM-dd or ISO-ish
          final parsed = DateTime.parse(profile.dob!);
          _dobController.text = DateFormat('ddMMyyyy').format(parsed);
        } catch (_) {
          // fallback: show raw if parsing fails
          _dobController.text = profile.dob!;
        }
      } else {
        _dobController.text = '';
      }

      _gender                   = profile.gender;
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Failed to load profile: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  UserProfile _buildEditedProfile() {
    return UserProfile(
      userId: _originalProfile!.userId, // ✅ preserve userId
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      photoUrl: _originalProfile?.photoUrl,
      dob: _dobController.text.trim().isEmpty
          ? null
          : _dobController.text.trim(),
      gender: _gender,
    );
  }


  bool _hasChanges(UserProfile edited) {
    if (_originalProfile == null) return true;
    return edited != _originalProfile;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final edited = _buildEditedProfile();

    if (!_hasChanges(edited)) {
      if (mounted) {
        showInfoDialog(
          context: context,
          title: 'No changes',
          message: 'There are no changes to update.',
        );
      }
      return;
    }

    final confirm = await showConfirmationDialog(
      context: context,
      title: 'Update profile?',
      message:
      'Updating your profile will replace your previous details. Continue?',
      confirmText: 'Yes, update',
      cancelText: 'Cancel',
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _service.saveProfile(edited);
      _originalProfile = edited;

      if (mounted) {
        // update global profile so app bar / menu refresh
        context.read<ProfileCubit>().updateProfile(edited);
        showInfoDialog(
          context: context,
          title: 'Profile updated',
          message: 'Your profile has been updated successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Failed to update profile: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _ProfileAvatar(
                displayName: _originalProfile?.firstName,
                photoUrl: _originalProfile?.photoUrl,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date of birth',
                  hintText: 'Tap to select',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final initialDate = DateTime(now.year - 18, now.month, now.day);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1900),
                    lastDate: now,
                  );
                  if (picked != null) {
                      final formatted = DateFormat('ddMMyyyy').format(picked);
                      _dobController.text = formatted;
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text('Female'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other'),
                  ),
                  DropdownMenuItem(
                    value: 'prefer_not_to_say',
                    child: Text('Prefer not to say'),
                  ),
                ],
                onChanged: (initialValue) {
                  setState(() => _gender = initialValue);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? displayName;
  final String? photoUrl;

  const _ProfileAvatar({
    required this.displayName,
    required this.photoUrl,
  });

  String _initials() {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      final parts = displayName!.trim().split(RegExp(r'\s+'));
      if (parts.length == 1) {
        return parts.first[0].toUpperCase();
      }
      return (parts.first[0] + parts.last[0]).toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primary.withAlpha(26),
            backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Text(
              _initials(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap avatar to change (coming soon)',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
