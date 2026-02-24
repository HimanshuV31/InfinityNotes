import 'dart:developer' as developer;
import 'dart:io';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:infinitynotes/services/auth/auth_exception.dart';
import 'package:infinitynotes/services/notifications/notification_service.dart';

/// Apple Sign-In Implementation
///
/// STATUS: Partially configured (pending Apple Developer account)
///
/// ✅ READY:
/// - Firebase OAuth redirect URI configured
/// - Code structure complete
/// - Error handling implemented
/// - Notification initialization added
///
/// ❌ NEEDS APPLE DEVELOPER ACCOUNT:
/// - Service ID: com.ehv.infinitynotes.firebase (placeholder)
/// - Team ID, Key ID, Private Key (for Firebase Console)
///
/// TO COMPLETE:
/// 1. Enroll in Apple Developer Program ($99/year)
/// 2. Follow steps in: APPLE_SIGN_IN_CONFIG.md
/// 3. Update clientId with actual Service ID
/// 4. Configure Firebase Console with Team ID + Auth Key
///
/// CURRENT BEHAVIOR:
/// - iOS simulator: Will fail (requires Apple Developer config)
/// - Android: Will work once Service ID added
/// - Email/Google Sign-In: ✅ Working alternatives

Future<UserCredential?> signInWithApple() async {
  try {
    developer.log('🍎 Step 1: Requesting Apple credentials...', name: 'AppleSignIn');

    // Request Apple credentials
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      // Web authentication options are ONLY required on Android
      webAuthenticationOptions: Platform.isAndroid
          ? WebAuthenticationOptions(
        // TODO: Replace with actual Service ID from Apple Developer Portal
        // Format: com.ehv.infinitynotes.firebase
        // See: APPLE_SIGN_IN_CONFIG.md
        clientId: "com.ehv.infinityNotes.firebase", // PLACEHOLDER
        redirectUri: Uri.parse(
          "https://infinity-notes-3101.firebaseapp.com/__/auth/handler", // ✅ Ready
        ),
      )
          : null,
    );

    developer.log('🍎 Step 2: Got Apple credential', name: 'AppleSignIn');
    developer.log('  - User ID: ${appleCredential.userIdentifier}', name: 'AppleSignIn');
    developer.log('  - Identity Token: ${appleCredential.identityToken != null ? "EXISTS" : "NULL"}', name: 'AppleSignIn');
    developer.log('  - Auth Code: EXISTS', name: 'AppleSignIn');

    // ✅ FIX: Check for null identityToken (iOS simulator bug)
    if (appleCredential.identityToken == null) {
      developer.log('🔥 THROWING: AppleSignInIdentityTokenNullException (simulator bug)', name: 'AppleSignIn');
      throw const AppleSignInIdentityTokenNullException();
    }

    developer.log('🍎 Step 3: Creating Firebase credential...', name: 'AppleSignIn');

    // Convert Apple credentials to Firebase credentials
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    developer.log('🍎 Step 4: Signing in with Firebase...', name: 'AppleSignIn');

    // Sign in with Firebase
    final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    developer.log('🍎 Step 5: SUCCESS! User UID: ${userCredential.user?.uid}', name: 'AppleSignIn');

    // ═══════════════════════════════════════════════════════════
    // 🔔 NEW: Initialize notifications after successful sign-in
    // ═══════════════════════════════════════════════════════════
    final user = userCredential.user;
    if (user != null) {
      developer.log('🔔 Step 6: Initializing notifications...', name: 'AppleSignIn');
      await NotificationService().initialize(user.uid);
      developer.log('🔔 Step 6: Notifications initialized', name: 'AppleSignIn');
    }

    return userCredential;

  } on FirebaseAuthException catch (e) {
    // Firebase-specific errors (network, invalid credential, etc.)
    developer.log('🔥 Firebase Auth Error: ${e.code} - ${e.message}', name: 'AppleSignIn', error: e);
    throw AuthException.fromCode(e.code); // Use your existing factory
  } on SignInWithAppleAuthorizationException catch (e) {
    // User cancelled Apple Sign-In or other Apple-specific error
    developer.log('🔥 Apple Authorization Error: ${e.code} - ${e.message}', name: 'AppleSignIn', error: e);
    if (e.code == AuthorizationErrorCode.canceled) {
      throw const AppleSignInUserCancelledException();
    }
    throw GenericAuthException('apple-signin-error: ${e.code}');
  } catch (e, stackTrace) {
    // Generic errors (network, unexpected errors, etc.)
    developer.log('🔥 Apple Sign-In failed: $e', name: 'AppleSignIn', error: e, stackTrace: stackTrace);
    rethrow; // Re-throw so BLoC can catch it
  }
}
