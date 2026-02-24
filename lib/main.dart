import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:infinitynotes/constants/routes.dart';
import 'package:infinitynotes/core/dependency_injection/service_locator.dart';
import 'package:infinitynotes/helpers/loading/loading_screen.dart';
import 'package:infinitynotes/services/auth/bloc/auth_bloc.dart';
import 'package:infinitynotes/services/auth/bloc/auth_event.dart';
import 'package:infinitynotes/services/auth/bloc/auth_state.dart';
import 'package:infinitynotes/services/notifications/notification_service.dart';
import 'package:infinitynotes/services/platform/app_version.dart';
import 'package:infinitynotes/services/profile/profile_cubit.dart';
import 'package:infinitynotes/services/theme/theme_notifier.dart';
import 'package:infinitynotes/utilities/generics/ui/dialogs.dart';
import 'package:infinitynotes/views/login_view.dart';
import 'package:infinitynotes/views/notes/create_update_note_view.dart';
import 'package:infinitynotes/views/notes/notes_view.dart';
import 'package:infinitynotes/views/register_view.dart';
import 'package:infinitynotes/views/verify_email_view.dart';

// ============================================================================
// GLOBAL DEEP LINK MANAGEMENT
// ============================================================================
final _appLinks = AppLinks();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String? _pendingDeepLink;
StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must be registered before Firebase.initializeApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await _initializeApp();

  // Set navigator key before UI renders
  NotificationService.setNavigatorKey(navigatorKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<ThemeNotifier>()),
        BlocProvider(create: (_) => getIt<AuthBloc>()),
      ],
      child: const MyApp(),
    ),
  );
}

// ============================================================================
// APP INITIALIZATION SEQUENCE
// ============================================================================
Future<void> _initializeApp() async {
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');

    await _configureFirestore();
    debugPrint('✅ Firestore configured');

    _setupConnectivityListener();
    debugPrint('✅ Connectivity listener active');

    await setupServiceLocator();
    debugPrint('✅ Service locator configured');

    await _initializeDeepLinking();
    debugPrint('✅ Deep linking initialized');

    await AppVersion.init();
    debugPrint('✅ App version loaded: ${AppVersion.version}');
  } catch (e, stackTrace) {
    debugPrint('❌ FATAL: App initialization failed');
    debugPrint('Error: $e');
    debugPrint('Stack: $stackTrace');
    rethrow;
  }
}

// ============================================================================
// FIRESTORE CONFIGURATION
// ============================================================================
Future<void> _configureFirestore() async {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}

// ============================================================================
// NETWORK CONNECTIVITY MONITORING
// ============================================================================
void _setupConnectivityListener() {
  _connectivitySubscription = Connectivity()
      .onConnectivityChanged
      .listen((List<ConnectivityResult> results) {
    final hasConnection =
    results.any((result) => result != ConnectivityResult.none);

    if (hasConnection) {
      debugPrint('🌐 Network restored: $results');
      FirebaseFirestore.instance.enableNetwork().catchError((e) {
        debugPrint('⚠️ Failed to reconnect Firestore: $e');
      });
    } else {
      debugPrint('🚫 Network disconnected');
    }
  }, onError: (error) {
    debugPrint('⚠️ Connectivity listener error: $error');
  });
}

// ============================================================================
// DEEP LINKING INITIALIZATION
// ============================================================================
Future<void> _initializeDeepLinking() async {
  try {
    final Uri? initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _pendingDeepLink = initialLink.toString();
      debugPrint('📎 Initial deep link captured: $_pendingDeepLink');
    }
  } catch (e) {
    debugPrint('⚠️ Deep link initialization failed: $e');
  }
}

// ============================================================================
// APP WIDGET (ROOT)
// ============================================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupDeepLinkListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed - checking network state');
      Connectivity().checkConnectivity().then((results) {
        final hasConnection = results.any((r) => r != ConnectivityResult.none);
        if (hasConnection) {
          FirebaseFirestore.instance.enableNetwork();
        }
      });
    }
  }

  void _setupDeepLinkListener() {
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      if (uri.host == 'note' && uri.pathSegments.isNotEmpty) {
        _pendingDeepLink = uri.toString();
        debugPrint('📎 Deep link received: $_pendingDeepLink');
        _processPendingDeepLink();
      }
    }, onError: (error) {
      debugPrint('⚠️ Deep link stream error: $error');
    });
  }

  void _processPendingDeepLink() {
    if (_pendingDeepLink != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          handleDeepLink(context, Uri.parse(_pendingDeepLink!));
          _pendingDeepLink = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, notifier, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Infinity Notes',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: notifier.themeMode,
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                final authBloc = context.read<AuthBloc>();
                if (authBloc.state is AuthStateUninitialized) {
                  debugPrint('🔥 Dispatching AuthEventInitialize');
                  authBloc.add(const AuthEventInitialize());
                }

                if (_pendingDeepLink != null) {
                  handleDeepLink(context, Uri.parse(_pendingDeepLink!));
                  _pendingDeepLink = null;
                }
              });

              return const HomePage();
            },
          ),
          routes: {
            CreateUpdateNoteRoute: (context) => const CreateUpdateNoteView(),
          },
          builder: (context, child) {
            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthStateLoggedIn) {
                  return BlocProvider(
                    create: (_) => ProfileCubit()..loadOrCreateProfile(),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        boldText: false,
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: child!,
                    ),
                  );
                }

                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    boldText: false,
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// HOME PAGE (AUTH STATE ROUTER)
// ============================================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.isLoading) {
          LoadingScreen().show(
            context: context,
            text: state.loadingText ?? "Please wait...",
          );
        } else {
          LoadingScreen().hide();
        }

        // Initialize notifications when user logs in
        if (state is AuthStateLoggedIn) {
          await NotificationService().initialize(state.user.id);
          if(!context.mounted) return;
        }

        if (state is AuthStateNeedsEmailVerification) {
          final shouldVerify = await showWarningDialog(
            context: context,
            title: "Verification Pending",
            message: "Please verify your email to continue.",
            buttonText: "Verify Now",
          );
          if (shouldVerify == true && context.mounted) {
            context.read<AuthBloc>().add(const AuthEventShouldVerifyEmail());
          }
        }

        if (state is AuthStateLoggedOut && !state.isLoading && context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      builder: (context, state) {
        debugPrint('🔍 Auth State: ${state.runtimeType}');

        return switch (state) {
          AuthStateLoggedIn() => const NotesView(),
          AuthStateNavigateToVerifyEmail() => const VerifyEmailView(),
          AuthStateLoggedOut() => const LoginView(),
          AuthStateRegistering() => const RegisterView(),
          AuthStateForgotPassword(hasSentEmail: true) => const LoginView(),
          _ => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        };
      },
    );
  }
}

// ============================================================================
// DEEP LINK HANDLER
// ============================================================================
void handleDeepLink(BuildContext context, Uri uri) {
  if (!context.mounted) return;

  debugPrint('🔗 Processing deep link: $uri');

  if (uri.host == 'note' && uri.pathSegments.length == 1) {
    final String noteId = uri.pathSegments[0];
    final authBloc = context.read<AuthBloc>();
    final currentState = authBloc.state;

    if (currentState is AuthStateLoggedIn) {
      Navigator.of(context).pushNamed(
        CreateUpdateNoteRoute,
        arguments: {
          'noteId': noteId,
          'isEditing': true,
        },
      );
      debugPrint('✅ Navigated to note: $noteId');
    } else {
      showCustomRoutingDialog(
        context: context,
        title: "Login Required",
        content: "Please login to access this note.",
        routeButtonText: "Login",
        onRoutePressed: () {
          authBloc.add(const AuthEventLogOut());
        },
        cancelButtonText: "Cancel",
      );
      debugPrint('⚠️ Login required to access note: $noteId');
    }
  } else {
    debugPrint('⚠️ Invalid deep link format: $uri');
  }
}

// ============================================================================
// THEME BUILDERS
// ============================================================================
ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3993ad),
      onPrimary: Colors.white,
      inversePrimary: Colors.black,
      surface: Colors.white,
      onSurface: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
    ),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3993ad),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    textTheme: const TextTheme(
      bodySmall: TextStyle(color: Colors.black54),
    ),
    dividerColor: Colors.black12,
    disabledColor: Colors.grey,
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF202124),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3993ad),
      onPrimary: Colors.white,
      inversePrimary: Colors.white,
      surface: Colors.black,
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.black,
    ),
    cardColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3993ad),
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    textTheme: const TextTheme(
      bodySmall: TextStyle(color: Colors.white54),
    ),
    dividerColor: Colors.white12,
    disabledColor: Colors.grey,
  );
}
