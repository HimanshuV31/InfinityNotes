import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<UserCredential?> signInWithApple() async {
  try {
    // Request Apple credentials
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      // Web authentication options are ONLY required on Android
      webAuthenticationOptions: Platform.isAndroid
          ? WebAuthenticationOptions(
        clientId: "com.yourcompany.serviceid", // Your Apple Service ID
        redirectUri: Uri.parse(
          "https://your-project-id.firebaseapp.com/__/auth/handler", // from Firebase console
        ),
      )
          : null,
    );

    // Convert Apple credentials to Firebase credentials
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    // Sign in with Firebase
    final userCredential =
    await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    return userCredential;
  } catch (e) {
    debugPrint("🔥 Apple Sign-In failed: $e");
    return null;
  }
}
