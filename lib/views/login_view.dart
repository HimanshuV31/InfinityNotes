import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinitynotes/services/auth/auth_exception.dart';
import 'package:infinitynotes/services/auth/auth_service.dart';
import 'package:infinitynotes/services/auth/bloc/auth_bloc.dart';
import 'package:infinitynotes/services/auth/bloc/auth_event.dart';
import 'package:infinitynotes/services/auth/bloc/auth_state.dart';
import 'package:infinitynotes/services/platform/platform_utils.dart';
import 'package:infinitynotes/utilities/generics/ui/custom_app_bar.dart';
import 'package:infinitynotes/utilities/generics/ui/dialogs.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthService.firebase();
  final bool hasAppleDevAccount = false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    context.read<AuthBloc>().add(AuthEventLogIn(email, password));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.primary;
    final foregroundColor = Theme.of(context).colorScheme.onPrimary;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateLoggedOut && state.exception != null) {
          final e = state.exception;
          if (e is AuthException) {
            showWarningDialog(
              context: context,
              title: e.title,
              message: e.message,
            );
            emailController.clear();
            passwordController.clear();
          }
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Infinity Notes | Login",
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor!,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor!,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthStateLoggedOut && state.isLoading;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    enabled: !isLoading, // ✅ Disable during loading
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                    enabled: !isLoading, // ✅ Disable during loading
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : login, // ✅ Disable during loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backgroundColor,
                      foregroundColor: foregroundColor,
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text("Login"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Registration button
                      TextButton(
                        onPressed: isLoading
                            ? null // ✅ Disable during loading
                            : () {
                          context
                              .read<AuthBloc>()
                              .add(const AuthEventShouldRegister());
                        },
                        child: const Text("New User? Register."),
                      ),

                      // Password recovery button
                      TextButton(
                        onPressed: isLoading
                            ? null // ✅ Disable during loading
                            : () async {
                          final email = emailController.text.trim();
                          final bool isEmailValid = RegExp(
                            r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
                          ).hasMatch(email);
                          if (!isEmailValid || email.isEmpty) {
                            showWarningDialog(
                              context: context,
                              title: "Invalid Email",
                              message: "Please enter a valid email address",
                            );
                            return;
                          }
                          final bool confirm =
                          await showConfirmDialog(context: context);
                          if (!confirm) return;
                          try {
                            if (!mounted) return;
                            context
                                .read<AuthBloc>()
                                .add(AuthEventResetPassword(email: email));
                            if (!mounted) return;
                            showWarningDialog(
                              context: context,
                              title: "Reset Email Sent",
                              message:
                              "Password Reset email has been sent if the email is "
                                  "registered. Otherwise, kindly do the registration.",
                            );
                          } on AuthException catch (e) {
                            final authError = AuthException.fromCode(e.code);
                            if (e.code == "invalid-credential" ||
                                e.code == "invalid-email") {
                              emailController.clear();
                            }
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(authError.message)),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Unknown Error: $e")),
                            );
                          }
                        },
                        child: const Text("Forgot Password?"),
                      ),
                    ],
                  ),

                  // Text stating Social Login
                  const SizedBox(height: 17),
                  Text(
                    "Or sign in with a social account",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Row for Social Logins
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google
                      GestureDetector(
                        onTap: isLoading
                            ? null // ✅ Disable during loading
                            : () async {
                          context.read<AuthBloc>().add(AuthEventGoogleSignIn());
                        },
                        child: Opacity(
                          opacity: isLoading ? 0.5 : 1.0, // ✅ Visual feedback
                          child: Column(
                            children: [
                              Image.asset('assets/icons/google_logo.png', height: 40),
                              const SizedBox(height: 4),
                              Text(
                                "Google",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Only add spacing + Apple button if on iOS
                      if (PlatformUtils.isIOS && hasAppleDevAccount==true) ...[
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: isLoading
                              ? null // ✅ Disable during loading
                              : () async {
                            context.read<AuthBloc>().add(const AuthEventAppleSignIn());
                          },
                          child: Opacity(
                            opacity: isLoading ? 0.5 : 1.0, // ✅ Visual feedback
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  children: [
                                    Image.asset('assets/icons/apple_logo.png',
                                        height: 40),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Apple",
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                // ✅ Show loading spinner on Apple button
                                if (isLoading)
                                  const Positioned(
                                    top: 0,
                                    child: SizedBox(
                                      height: 40,
                                      width: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
