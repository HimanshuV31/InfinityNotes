import 'package:infinitynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

import '../lib/services/auth/auth_exception.dart';
import '../lib/services/auth/auth_provider.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test('Should not be initialized to begin with', () {
      expect(provider.isInitialized, false);
    }); //test
    test('Cannot log out if not initialized', () {
      expect(
        provider.signOut(),
        throwsA(const TypeMatcher<NotInitializedException>()),
      );
    }); //test
    test('Should be able to initialize', () async {
      await provider.initialize();
    }); //test
    test('User should be null after initialization', () {
      expect(provider.currentUser, null);
    }); //test
    test(
      'Should be able to initialize in less than 2 seconds',
      () async {
        await provider.initialize();
        expect(provider.isInitialized, true);
      },
      timeout: const Timeout(Duration(seconds: 2)),
    ); //test
    test('Create user should delegate to login function', () async {

      //Bad Email
      final badEmailUser = provider.createUser(
        email: 'bademail@gmail.com',
        password: 'anypassword',
      );
      expect(
        badEmailUser,
        throwsA(const TypeMatcher<UserNotFoundAuthException>()),
      );

      //Bad Password
      final badPasswordUser = provider.createUser(
        email: 'ehv@gmail.com',
        password: 'badpassword',
      );
      expect(
        badPasswordUser,
        throwsA(const TypeMatcher<WrongPasswordAuthException>()),
      );

      //Create User
      final user = await provider.createUser(
        email: 'ehv@gmail.com',
        password: 'anypassword',
      );
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    }); //test

    //Verify Email
    test('Logged in user should be able to get verified', () {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    }); //test

    //Log Out and Log In
    test('Should be able to log out and log in again', () async {
      await provider.signOut();
      await provider.logIn(
        email: 'ehv@gmail.com',
        password: 'anypassword',
      );
      final user = provider.currentUser;
      expect(user, isNotNull);
    }); //test



  }); /*Group Mock Authentication*/
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;

  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(email: email, password: password);
  }

  @override
  // TODO: implement currentUser
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({required String email, required String password}) {
    if (!_isInitialized) throw NotInitializedException();
    if (email != 'ehv@gmail.com') throw UserNotFoundAuthException();
    if (password != 'anypassword') throw WrongPasswordAuthException();
    const user = AuthUser( id: 'my_id' ,isEmailVerified: false, email: 'ehv@gmail.com');
    _user = user;
    return Future.value(user);
  }

  @override
  Future<AuthUser?> logInWithApple() {
    // TODO: implement logInWithApple
    throw UnimplementedError();
  }

  @override
  Future<AuthUser?> logInWithGoogle() {
    // TODO: implement logInWithGoogle
    throw UnimplementedError();
  }

  @override
  Future<AuthUser?> reloadUser() {
    // TODO: implement reloadUser
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!_isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    const newUser = AuthUser(id: 'my_id',isEmailVerified: true, email: 'ehv@gmail.com');
    _user = newUser;
    // return Future.value();
  }

  @override
  Future<void> sendPasswordReset({required String email}) {
    // TODO: implement sendPasswordReset
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    if (!_isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }
}
