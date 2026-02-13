import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart';
import 'user_profile_service.dart';

class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final Object? error;

  const ProfileState({
    required this.profile,
    required this.isLoading,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    Object? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  const ProfileState.initial()
      : profile = null,
        isLoading = false,
        error = null;
}

class ProfileCubit extends Cubit<ProfileState> {
  final UserProfileService _service;
  final FirebaseAuth _auth;

  ProfileCubit({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _service = UserProfileService(
          firestore: firestore ?? FirebaseFirestore.instance,
          firebaseAuth: firebaseAuth ?? FirebaseAuth.instance,
        ),
        super(const ProfileState.initial());

  Future<void> loadOrCreateProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    emit(state.copyWith(isLoading: true, error: null));

    try {
      // 1) Try Firestore first
      final existing = await _service.loadProfile();
      emit(state.copyWith(profile: existing, isLoading: false));
    } on Exception {
      // 2) If not found, build from FirebaseAuth and save
      final displayName = user.displayName ?? '';
      final names = displayName.trim().split(RegExp(r'\s+'));

      final firstName = names.isNotEmpty && names.first.isNotEmpty
          ? names.first
          : 'User';
      final lastName =
      names.length > 1 ? names.sublist(1).join(' ') : null;

      final newProfile = UserProfile(
        firstName: firstName,
        lastName: lastName,
        photoUrl: user.photoURL,
        dob: null,
        gender: null,
      );

      await _service.saveProfile(newProfile);
      emit(state.copyWith(profile: newProfile, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e));
    }
  }

  Future<void> updateProfile(UserProfile updated) async {
    await _service.saveProfile(updated);
    emit(state.copyWith(profile: updated));
  }
}
