import 'package:infinity_notes/services/auth/auth_user.dart';
import 'package:infinity_notes/services/auth/i_auth_service.dart';
import 'package:infinity_notes/core/dependency_injection/service_locator.dart';

class AuthService implements IAuthService {
  final IAuthService provider;

  const AuthService(this.provider);

  factory AuthService.firebase() => AuthService(getIt<IAuthService>());

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    return await provider.createUser(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    return await provider.logIn(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() => provider.signOut();

  @override
  Future<void> sendEmailVerification() => provider.sendEmailVerification();

  @override
  Future<void> initialize() => provider.initialize();

  @override
  AuthUser? get currentUser => provider.currentUser;

  @override
  Future<void> sendPasswordReset({required String email}) =>
      provider.sendPasswordReset(email: email);

  @override
  Future<AuthUser?> logInWithGoogle() => provider.logInWithGoogle();

  @override
  Future<AuthUser?> logInWithApple() => provider.logInWithApple();

  @override
  Future<AuthUser?> reloadUser() => provider.reloadUser();
}
