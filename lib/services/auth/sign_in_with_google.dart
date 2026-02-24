import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:infinitynotes/services/platform/platform_utils.dart' show PlatformUtils;
import 'package:infinitynotes/services/notifications/notification_service.dart';

Future<UserCredential> signInWithGoogle() async {
  // ═══════════════════════════════════════════════════════════
  // WEB PLATFORM IMPLEMENTATION
  // ═══════════════════════════════════════════════════════════
  if (PlatformUtils.isWeb) {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());

      // Initialize notifications after successful sign-in
      final user = userCredential.user;
      if (user != null) {
        await NotificationService().initialize(user.uid);
      }

      return userCredential;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'web-popup-failed',
        message: 'Google Sign-In popup failed: ${e.toString()}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE/DESKTOP PLATFORM IMPLEMENTATION (v7.2.0+)
  // ═══════════════════════════════════════════════════════════
  final GoogleSignIn gsi = GoogleSignIn.instance;

  try {
    // Initialize GoogleSignIn instance (required in v7.2.0+)
    await gsi.initialize();

    // Authenticate user (v7.2.0 API - replaces deprecated signIn())
    final GoogleSignInAccount account = await gsi.authenticate();

    // Get authentication tokens (synchronous in v7.2.0+)
    final GoogleSignInAuthentication auth = account.authentication;

    // Verify idToken exists (critical security check)
    final String? idToken = auth.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google returned no ID token.',
      );
    }

    // Create Firebase credential with Google ID token
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    // Sign in to Firebase with Google credential
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Initialize notifications after successful sign-in
    final user = userCredential.user;
    if (user != null) {
      await NotificationService().initialize(user.uid);
    }

    return userCredential;

  } catch (e) {
    // Re-throw FirebaseAuthException as-is
    if (e is FirebaseAuthException) rethrow;

    // Wrap other exceptions in FirebaseAuthException
    throw FirebaseAuthException(
      code: 'google-sign-in-failed',
      message: 'Google Sign-In failed: ${e.toString()}',
    );
  }
}
