import "package:infinity_notes/constants/error_messages.dart";

abstract class AuthException implements Exception {
  final String code;

  const AuthException(this.code);

  String get message;
  String get title;

  @override
  String toString() => "AuthException($code): $message";

  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const InvalidEmailAuthException();
      case 'user-disabled':
        return const UserNotFoundAuthException();
      case 'user-not-found':
        return const UserNotFoundAuthException();
      case 'wrong-password':
        return const WrongPasswordAuthException();
      case 'invalid-credential':
        return const InvalidCredentialAuthException();
      case 'email-already-in-use':
        return const EmailAlreadyInUseAuthException();
      case 'weak-password':
        return const WeakPasswordAuthException();
      case 'network-request-failed':
        return const GenericAuthException('network-error');
      case 'too-many-requests':
        return const GenericAuthException('too-many-requests');
      case 'cancelled-popup-request':
        return const GenericAuthException('cancelled-popup-request');
      case 'popup-blocked':
        return const GenericAuthException('popup-blocked');
      case 'popup-closed-by-user':
        return const GenericAuthException('popup-closed-by-user');
      default:
        return GenericAuthException(code);
    }
  }
} /*class AuthException*/


class WeakPasswordAuthException extends AuthException {
  const WeakPasswordAuthException()
      : super('weak-password');

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('weak-password');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('weak-password');
}
class EmailAlreadyInUseAuthException extends AuthException {
  const EmailAlreadyInUseAuthException()
      : super('email-already-in-use' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('email-already-in-use');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('email-already-in-use');
}
class InvalidEmailAuthException extends AuthException {
  const InvalidEmailAuthException()
      : super('invalid-email' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('invalid-email');

  @override
  // TODO: implement title
  String get title =>  ErrorMessages.getAuthErrorTitle('invalid-email');
}
class UserNotFoundAuthException extends AuthException {
  const UserNotFoundAuthException()
      : super('user-not-found' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('user-not-found');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('user-not-found');
}
class InvalidCredentialAuthException extends AuthException {
  const InvalidCredentialAuthException()
      : super('invalid-credential' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('invalid-credential');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('invalid-credential');
}
class WrongPasswordAuthException extends AuthException {
  const WrongPasswordAuthException()
      : super('wrong-password' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('wrong-password');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('wrong-password');
}
class NetworkRequestFailedAuthException extends AuthException {
  const NetworkRequestFailedAuthException()
      : super('network-request-failed' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('network-request-failed');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('network-request-failed');
}
class TooManyRequestsAuthException extends AuthException {
  const TooManyRequestsAuthException()
      : super('too-many-requests' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('too-many-requests');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('too-many-requests');
}
class CancelledPopupRequestAuthException extends AuthException {
  const CancelledPopupRequestAuthException()
      : super('cancelled-popup-request' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('cancelled-popup-request');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('cancelled-popup-request');
}
class PopupBlockedAuthException extends AuthException {
  const PopupBlockedAuthException()
      : super('popup-blocked' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('popup-blocked');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('popup-blocked');
}
class PopupClosedByUserAuthException extends AuthException {
  const PopupClosedByUserAuthException()
      : super('popup-closed-by-user' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('popup-closed-by-user');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('popup-closed-by-user');
}
class PopupTimeoutAuthException extends AuthException {
  const PopupTimeoutAuthException()
      : super('popup-timeout' );

  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage('popup-timeout');

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle('popup-timeout');
}

class GenericAuthException extends AuthException {
  const GenericAuthException(super.code);
  @override
  // TODO: implement message
  String get message => ErrorMessages.getAuthErrorMessage(code);

  @override
  // TODO: implement title
  String get title => ErrorMessages.getAuthErrorTitle(code);
}