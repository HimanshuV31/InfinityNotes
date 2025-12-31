import 'package:flutter/foundation.dart' show immutable;

@immutable
abstract class AuthEvent{
  const AuthEvent();
}

class AuthEventInitialize extends AuthEvent{
  const AuthEventInitialize();
}
class AuthEventLogIn extends AuthEvent{
  final String email;
  final String password;
  const AuthEventLogIn(this.email, this.password);
}
class AuthEventGoogleSignIn extends AuthEvent{
  const AuthEventGoogleSignIn();
}
class AuthEventAppleSignIn extends AuthEvent{
  const AuthEventAppleSignIn();
}

class AuthEventLogOut extends AuthEvent{
  const AuthEventLogOut();
}

class AuthEventShouldVerifyEmail extends AuthEvent{
  const AuthEventShouldVerifyEmail();
}
class AuthEventSendEmailVerification extends AuthEvent{
  const AuthEventSendEmailVerification();
}

class AuthEventResetPassword extends AuthEvent{
  final String? email;
  const AuthEventResetPassword({this.email});
}

class AuthEventRegister extends AuthEvent{
  final String email;
  final String password;
  const AuthEventRegister({required this.email,required this.password,} );
}
class AuthEventShouldRegister extends AuthEvent{
  const AuthEventShouldRegister();
}

