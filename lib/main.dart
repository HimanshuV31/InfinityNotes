import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinity_notes/ai_summarize/ai_service.dart';
import 'package:infinity_notes/constants/routes.dart';
import 'package:infinity_notes/helpers/loading/loading_screen.dart';
import 'package:infinity_notes/services/auth/bloc/auth_bloc.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';
import 'package:infinity_notes/services/auth/firebase_auth_provider.dart';
import 'package:infinity_notes/services/feedback/emailjs_feedback_service.dart';
import 'package:infinity_notes/services/platform/app_version.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';
import 'package:infinity_notes/views/login_view.dart';
import 'package:infinity_notes/views/notes/create_update_note_view.dart';
import 'package:infinity_notes/views/notes/notes_view.dart';
import 'package:infinity_notes/views/register_view.dart';
import 'package:infinity_notes/views/verify_email_view.dart';
import 'package:infinity_notes/constants/api_keys.dart';


Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await AIService().initializeKeys(
    geminiKey: GeminiAPIKey(),
    // openAIKey: 'OpenAIAPIKey()',
  );
  await AppVersion.init();
  EmailJSFeedbackService.init();
  runApp(
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(FirebaseAuthProvider()),
      child: const MyApp(), // Now MyApp builds MaterialApp
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinity Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      routes: {
        CreateUpdateNoteRoute: (context) => const CreateUpdateNoteView(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // textScaler: TextScaler.linear(1.0), // Force 1.0 scale factor
            boldText: false,
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthEventInitialize());
  }
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        if(state.isLoading){
          LoadingScreen().show(
              context: context,
              text: state.loadingText ?? "Please wait..."
          );}else{
          LoadingScreen().hide();
        }
        if(state is AuthStateNeedsEmailVerification)
          {
            final bool? _shouldVerify = await showWarningDialog(
                context: context,
                title: "Verification Pending",
                message: "Please verify your email to continue.",
                buttonText: "Verify Now"
            );
            if (_shouldVerify == true) {
              context.read<AuthBloc>().add(const AuthEventShouldVerifyEmail());
            }
          }
        if(state is AuthStateNavigateToVerifyEmail){
          const VerifyEmailView();
        }
      },
        builder: (context, state) {
          if (state is AuthStateLoggedIn) {
            return const NotesView();
          } else if (state is AuthStateNavigateToVerifyEmail) {
            return const VerifyEmailView();
          } else if (state is AuthStateLoggedOut) {
            return const LoginView();
          }else if(state is AuthStateRegistering){
            return const RegisterView();
          }
          else if(state is AuthStateForgotPassword && state.hasSentEmail){
            return const  LoginView();
          }
          else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
    );
  }
}

