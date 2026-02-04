import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';

Future<UserCredential?> signInWithApple() async {
  try {
    print('🍎 Step 1: Requesting Apple credentials...');

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

    print('🍎 Step 2: Got Apple credential');
    print('  - User ID: ${appleCredential.userIdentifier}');
    print('  - Identity Token: ${appleCredential.identityToken != null ? "EXISTS" : "NULL"}');
    print('  - Auth Code: ${appleCredential.authorizationCode != null ? "EXISTS" : "NULL"}');

    // ✅ FIX: Check for null identityToken (simulator bug)
    if (appleCredential.identityToken == null) {
      throw const AppleSignInIdentityTokenNullException();
    }

    print('🍎 Step 3: Creating Firebase credential...');

    // Convert Apple credentials to Firebase credentials
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    print('🍎 Step 4: Signing in with Firebase...');

    // Sign in with Firebase
    final userCredential =
    await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    print('🍎 Step 5: SUCCESS! User UID: ${userCredential.user?.uid}');

    return userCredential;
  } on FirebaseAuthException catch (e) {
    // Firebase-specific errors (network, invalid credential, etc.)
    debugPrint("🔥 Firebase Auth Error: ${e.code} - ${e.message}");
    throw AuthException.fromCode(e.code); // Use your existing factory
  } on SignInWithAppleAuthorizationException catch (e) {
    // User cancelled Apple Sign-In or other Apple-specific error
    debugPrint("🔥 Apple Authorization Error: ${e.code} - ${e.message}");
    if (e.code == AuthorizationErrorCode.canceled) {
      throw const AppleSignInUserCancelledException();
    }
    throw GenericAuthException('apple-signin-error: ${e.code}');
  } catch (e) {
    // Generic errors (network, simulator bug, etc.)
    debugPrint("🔥 Apple Sign-In failed: $e");
    rethrow; // Re-throw so BLoC can catch it
  }
}
