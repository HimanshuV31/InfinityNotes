import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:infinity_notes/ai_summarize/ai_service.dart';
import 'package:infinity_notes/constants/api_keys.dart';
import 'package:infinity_notes/services/auth/firebase_auth_provider.dart';
import 'package:infinity_notes/services/auth/bloc/auth_bloc.dart';
import 'package:infinity_notes/services/feedback/emailjs_feedback_service.dart';
import 'package:infinity_notes/services/theme/theme_notifier.dart';
import 'package:infinity_notes/services/auth/i_auth_service.dart';

/// Global Service Locator instance
final getIt = GetIt.instance;

/// Initialize all dependencies (call this in main() before runApp)
Future<void> setupServiceLocator() async {
  // ========== EXTERNAL DEPENDENCIES ==========

  /// Firebase instances (singletons - shared across app)
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);

  // ========== AI SERVICE ==========

  /// AI Service initialization
  final aiService = AIService();
  await aiService.initializeKeys(
    geminiKey: ApiKeys.geminiAPIKey,
  );
  getIt.registerSingleton<AIService>(aiService);

  // ========== EMAIL SERVICE ==========

  /// Email feedback service
  EmailJSFeedbackService.init();
  getIt.registerSingleton<EmailJSFeedbackService>(
    EmailJSFeedbackService(),
  );

  // ========== THEME SERVICE ==========

  /// Theme notifier for app-wide theme management
  getIt.registerSingleton<ThemeNotifier>(ThemeNotifier());

  // ========== AUTH SERVICE ==========

  /// Auth Provider (Firebase implementation)
  getIt.registerSingleton<IAuthService>(
    FirebaseAuthProvider(
      firebaseAuth: getIt<FirebaseAuth>(),
      firebaseFirestore: getIt<FirebaseFirestore>(),
    ),
  );

  // ========== AUTH BLOC ==========

  /// AuthBloc (BLoC pattern for authentication state management)
  getIt.registerFactory<AuthBloc>(
        () => AuthBloc(getIt<IAuthService>()),
  );
}
