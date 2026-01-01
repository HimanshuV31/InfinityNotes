// ══════════════════════════════════════════════════════════════════════════════
// SERVICE LOCATOR - DEPENDENCY INJECTION CONTAINER
// ══════════════════════════════════════════════════════════════════════════════
// Purpose: Centralized dependency management using GetIt service locator pattern
// Architecture: Follows Dependency Inversion Principle (DIP) for loose coupling
// Initialization: Called once in main() before runApp() to setup all services
// Pattern: Singleton for shared instances, Factory for per-use instances
// ══════════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For .env loading
import 'package:get_it/get_it.dart';
import 'package:infinity_notes/ai_summarize/ai_service.dart';
import 'package:infinity_notes/constants/api_keys.dart';
import 'package:infinity_notes/services/auth/firebase_auth_provider.dart';
import 'package:infinity_notes/services/auth/bloc/auth_bloc.dart';
import 'package:infinity_notes/services/feedback/emailjs_feedback_service.dart';
import 'package:infinity_notes/services/theme/theme_notifier.dart';
import 'package:infinity_notes/services/auth/i_auth_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// GLOBAL SERVICE LOCATOR INSTANCE
// ══════════════════════════════════════════════════════════════════════════════
/// GetIt instance for dependency injection across the app
/// Usage: getIt<ServiceType>() to retrieve registered services
/// Example: final authService = getIt<IAuthService>();
final getIt = GetIt.instance;

// ══════════════════════════════════════════════════════════════════════════════
// SETUP SERVICE LOCATOR - MAIN INITIALIZATION FUNCTION
// ══════════════════════════════════════════════════════════════════════════════
/// Initialize all dependencies (call this in main() before runApp)
///
/// Initialization Order:
/// 1. Load environment variables from .env file
/// 2. Validate API keys are present
/// 3. Register Firebase services (Auth, Firestore)
/// 4. Initialize AI service with API keys
/// 5. Setup email feedback service
/// 6. Register theme notifier
/// 7. Setup authentication services (Provider + BLoC)
///
/// Throws:
/// - Exception if .env file not found
/// - Exception if API keys are missing/invalid
/// - Exception if service initialization fails
Future<void> setupServiceLocator() async {
  // ════════════════════════════════════════════════════════════════════════════
  // STEP 1: LOAD ENVIRONMENT VARIABLES
  // ════════════════════════════════════════════════════════════════════════════
  /// Load .env file containing sensitive API keys
  /// File location: project_root/.env
  /// Required keys: GEMINI_API_KEY (mandatory), OPENAI_API_KEY (optional)
  /// CRITICAL: This MUST run before any service accesses ApiKeys class
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env loaded successfully');
  } catch (e) {
    debugPrint('❌ FATAL: .env loading failed: $e');
    debugPrint('Ensure .env exists in project root with GEMINI_API_KEY');
    rethrow; // Fatal error - cannot proceed without API keys
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 2: VALIDATE API KEYS
  // ════════════════════════════════════════════════════════════════════════════
  /// Verify that required API keys are configured in .env
  /// Prevents runtime failures when AI services are accessed
  if (!ApiKeys.areKeysConfigured) {
    debugPrint('❌ FATAL: API keys not configured in .env');
    throw Exception('Missing GEMINI_API_KEY in .env file');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // EXTERNAL DEPENDENCIES - FIREBASE SERVICES
  // ════════════════════════════════════════════════════════════════════════════
  /// Firebase instances (singletons - shared across entire app lifecycle)
  /// These are already initialized by Firebase.initializeApp() in main()
  /// Registration allows dependency injection into auth/storage services

  /// Firebase Authentication instance for user auth operations
  /// Usage: getIt<FirebaseAuth>() anywhere in the app
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);

  /// Firebase Firestore instance for database operations
  /// Usage: getIt<FirebaseFirestore>() anywhere in the app
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);

  // ════════════════════════════════════════════════════════════════════════════
  // AI SERVICE - GEMINI API INTEGRATION
  // ════════════════════════════════════════════════════════════════════════════
  /// AI Service for note summarization and AI-powered features
  /// Singleton pattern - single instance shared across app
  /// Initialized with Gemini API key from .env
  final aiService = AIService();
  await aiService.initializeKeys(
    geminiKey: ApiKeys.geminiAPIKey, // Loaded from .env via ApiKeys wrapper
  );
  getIt.registerSingleton<AIService>(aiService);

  // ════════════════════════════════════════════════════════════════════════════
  // EMAIL SERVICE - EMAILJS FEEDBACK
  // ════════════════════════════════════════════════════════════════════════════
  /// Email feedback service for sending user feedback via EmailJS
  /// Singleton pattern - maintains connection state
  /// Static init() call configures EmailJS with service credentials
  EmailJSFeedbackService.init();
  getIt.registerSingleton<EmailJSFeedbackService>(
    EmailJSFeedbackService(),
  );

  // ════════════════════════════════════════════════════════════════════════════
  // THEME SERVICE - APP-WIDE THEME MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════════
  /// Theme notifier for dynamic theme switching (light/dark/system)
  /// Singleton pattern - notifies all widgets listening to theme changes
  /// Usage: getIt<ThemeNotifier>().toggleTheme() or listen for updates
  getIt.registerSingleton<ThemeNotifier>(ThemeNotifier());

  // ════════════════════════════════════════════════════════════════════════════
  // AUTH SERVICE - FIREBASE AUTHENTICATION PROVIDER
  // ════════════════════════════════════════════════════════════════════════════
  /// Auth Provider implementing IAuthService interface (DIP compliance)
  /// Singleton pattern - maintains auth state throughout app lifecycle
  /// Depends on FirebaseAuth and FirebaseFirestore (injected via getIt)
  /// Registered as IAuthService interface type for abstraction
  getIt.registerSingleton<IAuthService>(
    FirebaseAuthProvider(
      firebaseAuth: getIt<FirebaseAuth>(), // Dependency injection
      firebaseFirestore: getIt<FirebaseFirestore>(), // Dependency injection
    ),
  );

  // ════════════════════════════════════════════════════════════════════════════
  // AUTH BLOC - AUTHENTICATION STATE MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════════
  /// AuthBloc for BLoC pattern-based authentication state management
  /// Factory pattern - new instance per widget tree (avoid state leaks)
  /// Depends on IAuthService (injected via getIt)
  /// Usage: BlocProvider will call getIt<AuthBloc>() to get new instance
  getIt.registerFactory<AuthBloc>(
        () => AuthBloc(getIt<IAuthService>()), // Dependency injection
  );

  debugPrint('✅ All services initialized successfully');
}

// ══════════════════════════════════════════════════════════════════════════════
// USAGE EXAMPLES
// ══════════════════════════════════════════════════════════════════════════════
//
// 1. In main.dart:
//    await setupServiceLocator();
//    runApp(MyApp());
//
// 2. Retrieve singleton service:
//    final authService = getIt<IAuthService>();
//    await authService.signIn(email, password);
//
// 3. Retrieve factory instance (new each time):
//    final authBloc = getIt<AuthBloc>();
//    authBloc.add(LoginEvent());
//
// 4. In BlocProvider:
//    BlocProvider<AuthBloc>(
//      create: (_) => getIt<AuthBloc>(),
//      child: LoginScreen(),
//    )
//
// ══════════════════════════════════════════════════════════════════════════════
// ERROR HANDLING
// ══════════════════════════════════════════════════════════════════════════════
//
// Common Issues:
// 1. ".env file not found" → Ensure .env exists in project root
// 2. "API keys not configured" → Check GEMINI_API_KEY in .env
// 3. "Service not registered" → Ensure setupServiceLocator() was called
// 4. "Type mismatch" → Register with correct interface type (e.g., IAuthService)
//
// ══════════════════════════════════════════════════════════════════════════════
