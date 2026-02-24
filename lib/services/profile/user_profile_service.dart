import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_profile.dart';

class UserProfileService {
  static const _cacheKeyPrefix = 'user_profile_';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  UserProfileService({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth;

  String get _uid {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('No logged-in user for profile operations');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _docRef =>
      _firestore.collection('users').doc(_uid);

  /// Load profile with this priority:
  /// 1. Firestore (if exists)
  /// 2. Local cache
  /// 3. Seed from FirebaseAuth user
  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cacheKeyPrefix$_uid';

    // 1) Try Firestore
    final snapshot = await _docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() ?? {};
      final profile = UserProfile.fromMap(data);
      await _saveToCache(prefs, cacheKey, profile);
      return profile;
    }

    // 2) Try cache
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return UserProfile.fromMap(map);
      } catch (_) {
        // ignore corrupt cache
      }
    }

    // 3) Seed from FirebaseAuth user
    final authUser = _firebaseAuth.currentUser;
    if (authUser != null) {
      final seeded = _seedFromAuthUser(authUser);
      // Do NOT write to Firestore yet; only when user saves.
      await _saveToCache(prefs, cacheKey, seeded);
      return seeded;
    }

    // Fallback empty
    return UserProfile.empty();
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cacheKeyPrefix$_uid';

    // Write to Firestore
    await _docRef.set(profile.toMap(), SetOptions(merge: true));

    // Update cache
    await _saveToCache(prefs, cacheKey, profile);
  }

  Future<void> _saveToCache(
      SharedPreferences prefs,
      String key,
      UserProfile profile,
      ) async {
    await prefs.setString(key, jsonEncode(profile.toMap()));
  }

  UserProfile _seedFromAuthUser(User user) {
    final displayName = user.displayName?.trim() ?? '';
    String firstName = '';
    String? lastName;

    if (displayName.isNotEmpty) {
      final parts = displayName.split(RegExp(r'\s+'));
      firstName = parts.first;
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    // Fallback: derive firstName from email prefix if needed
    if (firstName.isEmpty && user.email != null) {
      final emailName = user.email!.split('@').first;
      if (emailName.isNotEmpty) {
        firstName = emailName;
      }
    }

    return UserProfile(
      userId: user.uid, // ✅ ADD userId here
      firstName: firstName.isEmpty ? 'User' : firstName,
      lastName: lastName,
      photoUrl: user.photoURL,
      dob: null,
      gender: null,
    );
  }
}
