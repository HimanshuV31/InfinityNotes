import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';
import 'package:infinity_notes/services/auth/i_auth_service.dart';
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(IAuthService authService) : super(const AuthStateUninitialized(isLoading: true)) {
    //Initialize
    // add(const AuthEventInitialize());
    on<AuthEventInitialize>((event, emit) async {
      try {
        await authService.initialize();
        try {
          await authService.reloadUser();
        } catch (e) {
          debugPrint('⚠️ AuthBloc: Error reloading user - $e');
        }
        final user = authService.currentUser;
        if (user == null) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
        } else if (!user.isEmailVerified) {
          emit(const AuthStateNeedsEmailVerification(isLoading: false));
        } else {
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        }
      } catch (e) {
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      }
    });

    //Login
    on<AuthEventLogIn>((event, emit) async {
      emit(const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: "Logging in... Please Wait..",
      ));
      final email= event.email;
      final password = event.password;
      try {
        await authService.logIn(
          email: email,
          password:password,
        );
        final freshUser= await authService.reloadUser();
        if (freshUser == null) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          return;
        }
        if (!freshUser.isEmailVerified) {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          emit(const AuthStateNeedsEmailVerification(isLoading: false));
        } else {
          emit(const AuthStateLoggedOut(exception: null, isLoading: false));
          emit(AuthStateLoggedIn(user: freshUser, isLoading: false));
        }
      } on AuthException catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      } on Exception catch (e){
        emit(AuthStateLoggedOut(
            exception: GenericAuthException(e.toString()),
            isLoading: false));
      }
    });
    //Google Login
    on<AuthEventGoogleSignIn>((event, emit) async {
      emit(const AuthStateLoggedOut(exception: null, isLoading: true));
      try {
        final user = await authService.logInWithGoogle();
        if(user!=null){
          emit( AuthStateLoggedIn(user:user, isLoading: false));
        }
      } on AuthException catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
        }
    });
    //Apple Login
    //Apple Login
    on<AuthEventAppleSignIn>((event, emit) async {
      emit(const AuthStateLoggedOut(exception: null, isLoading: true));
      try {
        final user = await authService.logInWithApple();
        if (user != null) {
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        } else {
          // ✅ FIX: Handle null return (shouldn't happen with new throw logic, but defensive)
          emit(const AuthStateLoggedOut(
            exception: GenericAuthException('apple-signin-null-user'),
            isLoading: false,
          ));
        }
      } on AuthException catch (e) {
        // Your custom auth exceptions (from sign_in_with_apple.dart)
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      } on Exception catch (e) {
        // ✅ FIX: Catch generic exceptions (network errors, etc.)
        emit(AuthStateLoggedOut(
          exception: GenericAuthException(e.toString()),
          isLoading: false,
        ));
      }
    });

    //Logout
    on<AuthEventLogOut>((event, emit) async {
      try {
        await authService.signOut();
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } on AuthException catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      } on Exception catch (e){
        emit(AuthStateLoggedOut(
            exception: GenericAuthException(e.toString()),
            isLoading: false));
      }
    });
    //Register
    on<AuthEventRegister>((event,emit)async{
      final email = event.email;
      final password = event.password;
      try {
        await authService.createUser(
          email: email,
          password: password,
        );
        emit(const AuthStateNeedsEmailVerification(isLoading: false));
      } on AuthException catch (e) {
        emit(AuthStateRegistering(exception: e, isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(
          exception: GenericAuthException(e.toString()),
          isLoading: false,
        ));
      }
    });
    //Should Register
    on<AuthEventShouldRegister>((event, emit) {
      emit(const AuthStateRegistering(
        exception: null,
        isLoading: false,
      ));
    });
    //Should Verify Email
    on<AuthEventShouldVerifyEmail>((event, emit) async {
      emit(const AuthStateNavigateToVerifyEmail());
    });
    //Send Verification Email
    on<AuthEventSendEmailVerification>((event, emit) async {
      await authService.sendEmailVerification();
      emit(state);
    });
    //Reset Password
    on<AuthEventResetPassword>((event, emit) async {
      emit(const AuthStateForgotPassword(
        exception: null,
        isLoading: true,
        hasSentEmail: false,
      ));
      final email = event.email;
      if (email == null || email.isEmpty) {
        emit(const AuthStateForgotPassword(
          exception: null,
          isLoading: false,
          hasSentEmail: false,
        ));
        return;
      }
      bool didSendEmail;
      Exception? exception;
      try {
        await authService.sendPasswordReset(email: email);
        didSendEmail = true;
        exception = null;
      } on AuthException catch (e) {
        didSendEmail = false;
        exception = e;
      } on Exception catch (e) {
        didSendEmail = false;
        exception = GenericAuthException(e.toString());
      }
      emit(AuthStateForgotPassword(
        exception: exception,
        isLoading: false,
        hasSentEmail: didSendEmail,
      ));
    });
  }
}
