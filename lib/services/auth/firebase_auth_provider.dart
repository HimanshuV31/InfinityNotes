import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, FirebaseAuth, GoogleAuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:infinitynotes/services/auth/auth_exception.dart';
import 'package:infinitynotes/services/auth/i_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:infinitynotes/services/auth/auth_user.dart';
import 'package:infinitynotes/services/auth/sign_in_with_apple.dart';
import 'package:infinitynotes/services/platform/platform_utils.dart';
import 'package:infinitynotes/services/notifications/notification_service.dart';

class FirebaseAuthProvider implements IAuthService {
  // Store injected dependencies as final fields
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;

  // Constructor accepts dependencies from outside
  FirebaseAuthProvider({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
  })  : _firebaseAuth = firebaseAuth,
        _firebaseFirestore = firebaseFirestore;

  @override
  Future<void> initialize() async {
    // Firebase initialization moved to main.dart
    // This method is now a no-op placeholder for future auth setup
    // (e.g., token refresh listeners, session management)
  }

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async
  {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
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
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return AuthUser.fromFirebase(user);
    }
    return null;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async
  {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Reload user to get latest profile data
      await _firebaseAuth.currentUser?.reload();
      final user = currentUser;

      if (user != null) {
        await NotificationService().initialize(user.id);
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
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;
      if (refreshedUser != null) {
        return AuthUser.fromFirebase(refreshedUser);
      }
    }
    return null;
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
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
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firebaseAuth.signOut();
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
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }

  @override
  Future<AuthUser?> logInWithGoogle() async {
    try {
      // Web implementation
      if (PlatformUtils.isWeb) {
        final userCred = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
        return userCred.user != null ? AuthUser.fromFirebase(userCred.user!) : null;
      }

      // Mobile/Desktop - v7.2.0 implementation
      final gsi = GoogleSignIn.instance;

      // Initialize first (v7.2.0 requirement)
      await gsi.initialize();

      // Use authenticate() instead of signIn()
      final account = await gsi.authenticate();

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw GenericAuthException('missing-id-token');
      }

      final oauth = GoogleAuthProvider.credential(idToken: idToken);
      final userCred = await _firebaseAuth.signInWithCredential(oauth);

      return userCred.user != null ? AuthUser.fromFirebase(userCred.user!) : null;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException(e.toString());
    }
  }


  @override
  Future<AuthUser?> logInWithApple() async {
    try {
      final userCredential = await signInWithApple();  // ✅ Now uses your diagnostic version

      return userCredential?.user != null
          ? AuthUser.fromFirebase(userCredential!.user!)
          : null;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw GenericAuthException("$e");
    }
  }

}
