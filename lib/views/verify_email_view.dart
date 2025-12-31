import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/services/auth/auth_exception.dart';
import 'package:infinity_notes/services/auth/auth_service.dart';
import 'package:infinity_notes/services/auth/bloc/auth_bloc.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';
import 'package:infinity_notes/utilities/generics/ui/custom_app_bar.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  bool _isSent = false;
  final auth = AuthService.firebase();
  CloseDialog? _closeDialogHandle;

  Future<void> sendVerificationEmail() async {
    final user = auth.currentUser;
    if (user != null && !user.isEmailVerified) {
      context.read<AuthBloc>().add(const AuthEventSendEmailVerification());
      setState(() => _isSent = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent!")),
      );
    }
  }

  Future<void> checkVerified() async {
    await auth.reloadUser();
    final isVerified = auth.currentUser?.isEmailVerified ?? false;
    if (!mounted) return;
    if (isVerified) {
      context.read<AuthBloc>().add(const AuthEventLogOut());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Still not verified")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.primary;
    final foregroundColor = Theme.of(context).colorScheme.onPrimary;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
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
            showWarningDialog(
              context: context,
              title: e.title,
              message: e.message,
            );
          }
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Infinity Notes | Verify Email",
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor!,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor!,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Theme.of(context).appBarTheme.foregroundColor,
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthEventLogOut()),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Please verify your email.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSent ? null : sendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                  ),
                  child: const Text("Send Verification Email"),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: checkVerified,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: foregroundColor,
                  ),
                  child: const Text("I have verified"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
