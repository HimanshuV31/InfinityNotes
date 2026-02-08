import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:infinitynotes/services/auth/auth_user.dart';

@immutable
abstract class AuthState {
  final bool isLoading;
  final String? loadingText;

  const AuthState({
    required this.isLoading,
    this.loadingText = "Loading... Please wait.",
  });
}

class AuthStateLoggedIn extends AuthState {
  const AuthStateLoggedIn({
    required this.user,
    required super.isLoading,
  });
  final AuthUser user;
}

class AuthStateNeedsEmailVerification extends AuthState {
  const AuthStateNeedsEmailVerification({required super.isLoading,});
}
class AuthStateNavigateToVerifyEmail extends AuthState{
  const AuthStateNavigateToVerifyEmail({ super.isLoading = false});
}

class AuthStateLoggedOut extends AuthState with EquatableMixin {
  final Exception? exception;

  const AuthStateLoggedOut({
    required this.exception,
    required super.isLoading,
    super.loadingText = null,
  });
  @override
  List<Object?> get props => [exception, isLoading];
}

class AuthStateUninitialized extends AuthState {

  const AuthStateUninitialized({required super.isLoading});
}

class AuthStateRegistering extends AuthState {
  final Exception? exception;

  const AuthStateRegistering({
    required this.exception,
    required super.isLoading,
  });
}

class AuthStateForgotPassword extends AuthState {
  final Exception? exception;
  final bool hasSentEmail;
  const AuthStateForgotPassword({
    required this.exception,
    required super.isLoading,
    required this.hasSentEmail,
  });
}