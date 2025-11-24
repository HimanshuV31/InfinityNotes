import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  final String id;
  final String email;
  final bool isEmailVerified;

  // ✅ NEW: Add these fields
  final String? displayName;
  final String? photoURL;

  const AuthUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    this.displayName,  // ✅ NEW
    this.photoURL,     // ✅ NEW
  });

  factory AuthUser.fromFirebase(User user) => AuthUser(
    id: user.uid,
    email: user.email!,
    isEmailVerified: user.emailVerified,
    displayName: user.displayName,  // ✅ NEW
    photoURL: user.photoURL,        // ✅ NEW
  );
}
