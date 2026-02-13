import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinitynotes/helpers/loading/loading_screen.dart';
import 'package:infinitynotes/services/auth/auth_exception.dart';
import 'package:infinitynotes/services/auth/bloc/auth_bloc.dart';
import 'package:infinitynotes/services/auth/bloc/auth_event.dart';
import 'package:infinitynotes/services/auth/bloc/auth_state.dart';
import 'package:infinitynotes/utilities/generics/ui/custom_app_bar.dart';
import 'package:infinitynotes/utilities/generics/ui/dialogs.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isEmailValid = false;
  final bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  CloseDialog? _closeDialogHandle;

  // Password rules tracking
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  bool _passwordsMatch = false;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _validatePassword(String password) {
    setState(() {
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasMinLength = password.length >= 8;
      _passwordsMatch = password == _confirmPasswordController.text;
    });
  }

  Future<void> register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (!_formKey.currentState!.validate()) return;
    if (!_passwordsMatch) return;
    context.read<AuthBloc>().add(
      AuthEventRegister(email: email, password: password),
    );
  }

  Widget _buildPasswordCriteria(String text, bool condition) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: condition ? Colors.green : Colors.red),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.primary;
    final foregroundColor = Theme.of(context).colorScheme.onPrimary;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.isLoading) {
          LoadingScreen().show(
              context: context, text: state.loadingText ?? "Please wait...");
        } else {
          LoadingScreen().hide();
        }
        if (state is AuthStateLoggedOut && state.exception != null) {
          final closeDialog = _closeDialogHandle;
          if (!state.isLoading && closeDialog != null) {
            closeDialog();
            _closeDialogHandle = null;
          } else if (state.isLoading && closeDialog == null) {
            _closeDialogHandle = showLoadingDialog(
              context: context,
              text: "Loading... .. .",
            );
          }
          final e = state.exception;
          if (e is AuthException) {
            await showWarningDialog(
              context: context,
              title: e.title,
              message: e.message,
            );
          }
        } else if (state is AuthStateRegistering &&
            state.exception != null &&
            !state.isLoading) {
          final closeDialog = _closeDialogHandle;
          if (closeDialog != null) {
            closeDialog();
            _closeDialogHandle = null;
          }
          await showWarningDialog(
            context: context,
            title: "Registration Error",
            message: state.exception.toString(),
          );
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Infinity Notes | Register",
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor!,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor!,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Email
                TextFormField(
                  controller: _emailController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Email",
                    suffixIcon: Icon(
                      _isEmailValid ? Icons.check_circle : Icons.cancel,
                      color: _isEmailValid ? Colors.green : Colors.red,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      _isEmailValid = isValidEmail(value.trim());
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    } else if (!isValidEmail(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: _passwordController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) {
                    _validatePassword(value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    } else if (!_hasUpperCase ||
                        !_hasLowerCase ||
                        !_hasNumber ||
                        !_hasSpecialChar ||
                        !_hasMinLength) {
                      return 'Password does not meet all criteria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  onChanged: (value) {
                    setState(() {
                      _passwordsMatch = value == _passwordController.text;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Password Criteria
                _buildPasswordCriteria(
                  "At least 1 uppercase letter",
                  _hasUpperCase,
                ),
                _buildPasswordCriteria(
                  "At least 1 lowercase letter",
                  _hasLowerCase,
                ),
                _buildPasswordCriteria("At least 1 number", _hasNumber),
                _buildPasswordCriteria("Minimum 8 characters", _hasMinLength),
                _buildPasswordCriteria(
                  "At least 1 special character",
                  _hasSpecialChar,
                ),
                _buildPasswordCriteria("Passwords match", _passwordsMatch),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                  ),
                  child: const Text("Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
