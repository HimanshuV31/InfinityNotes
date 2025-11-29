import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, FirebaseAuth, OAuthProvider, GoogleAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/auth_provider.dart';
import 'package:infinity_notes/services/auth/auth_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:infinity_notes/services/platform/platform_utils.dart';
import 'package:infinity_notes/firebase_options.dart';

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = currentUser;
      if (user != null) {
        return user;
      } else {
        throw const UserNotFoundAuthException();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }

  @override
  AuthUser? get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    }
    return null;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Reload user to get latest profile data
      await FirebaseAuth.instance.currentUser?.reload();
      final user = currentUser;

      if (user != null) {
        return user;
      } else {
        throw const UserNotFoundAuthException();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }

  @override
  Future<AuthUser?> reloadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null) {
        return AuthUser.fromFirebase(refreshedUser);
      }
    }
    return null;
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      } else {
        throw const UserNotFoundAuthException();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseAuth.instance.signOut();
      } else {
        throw const UserNotFoundAuthException();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }

  @override
  Future<AuthUser?> logInWithGoogle() async {
    try {
      if (PlatformUtils.isWeb) {
        final userCred = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider(),
        );
        return userCred.user != null
            ? AuthUser.fromFirebase(userCred.user!)
            : null;
      }

      final gsi = GoogleSignIn.instance;
      await gsi.initialize();

      final account = await gsi.authenticate();
      final idToken = (account.authentication).idToken;
      if (idToken == null) {
        throw GenericAuthException('missing-id-token');
      }

      final oauth = GoogleAuthProvider.credential(idToken: idToken);
      final userCred = await FirebaseAuth.instance.signInWithCredential(oauth);

      return userCred.user != null
          ? AuthUser.fromFirebase(userCred.user!)
          : null;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }

  @override
  Future<AuthUser?> logInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      return userCredential.user != null
          ? AuthUser.fromFirebase(userCredential.user!)
          : null;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }
}
