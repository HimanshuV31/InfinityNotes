import 'package:infinitynotes/services/auth/auth_user.dart';

abstract class AuthProvider{
  Future<void> initialize();

  AuthUser? get currentUser;
  Future<AuthUser> logIn(
      {required String email,required String password});
  Future<AuthUser> createUser(
      {required String email, required String password});
  Future<AuthUser?> logInWithGoogle();
  Future<AuthUser?> logInWithApple();

  Future<void> signOut();
  Future<void> sendEmailVerification();
  Future<void> sendPasswordReset({required String email});

  Future<AuthUser?> reloadUser();
}
