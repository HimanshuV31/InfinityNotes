import 'package:infinitynotes/services/auth/auth_user.dart';

abstract class IAuthService {
  Future<void> initialize();

  AuthUser? get currentUser;

  Future<AuthUser> logIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AuthUser> createUser({
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  Future<void> sendPasswordReset({required String email});

  Future<AuthUser?> logInWithGoogle();

  Future<AuthUser?> logInWithApple();

  Future<AuthUser?> reloadUser();
}
