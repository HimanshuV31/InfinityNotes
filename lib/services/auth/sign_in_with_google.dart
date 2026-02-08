import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:infinitynotes/services/platform/platform_utils.dart' show PlatformUtils;

Future<UserCredential> signInWithGoogle() async {
  // Web implementation remains the same
  if (PlatformUtils.isWeb) {
    try {
      return await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } catch (e) {
      throw FirebaseAuthException(
        code: 'web-popup-failed',
        message: 'Google Sign-In popup failed: ${e.toString()}',
      );
    }
  }

  // Mobile/Desktop - v7.2.0 implementation
  final GoogleSignIn gsi = GoogleSignIn.instance;

  try {
    // Initialize GoogleSignIn instance (v7.2.0 requirement)
    await gsi.initialize();

    // Use authenticate() instead of signIn() for v7.2.0
    // This handles user interaction properly
    final GoogleSignInAccount? account = await gsi.authenticate();

    if (account == null) {
      throw FirebaseAuthException(
        code: 'canceled',
        message: 'Sign-in aborted by user.',
      );
    }

    // Get authentication - synchronous in v7.2.0+
    final GoogleSignInAuthentication auth = account.authentication;

    // Verify idToken exists
    final String? idToken = auth.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google returned no ID token.',
      );
    }

    // Create credential with idToken only (v7.2.0 spec)
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    if (e is FirebaseAuthException) rethrow;
    throw FirebaseAuthException(
      code: 'google-sign-in-failed',
      message: 'Google Sign-In failed: ${e.toString()}',
    );
  }
}
