import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ ADD THIS IMPORT
import 'package:infinity_notes/constants/routes.dart';
import 'package:infinity_notes/helpers/loading/loading_screen.dart';
import 'package:infinity_notes/services/auth/bloc/auth_bloc.dart';
import 'package:infinity_notes/services/auth/bloc/auth_event.dart';
import 'package:infinity_notes/services/auth/bloc/auth_state.dart';
import 'package:infinity_notes/services/platform/app_version.dart';
import 'package:infinity_notes/services/theme/theme_notifier.dart';
import 'package:infinity_notes/utilities/generics/ui/dialogs.dart';
import 'package:infinity_notes/views/login_view.dart';
import 'package:infinity_notes/views/notes/create_update_note_view.dart';
import 'package:infinity_notes/views/notes/notes_view.dart';
import 'package:infinity_notes/views/register_view.dart';
import 'package:infinity_notes/views/verify_email_view.dart';
import 'package:provider/provider.dart';
import 'package:infinity_notes/core/dependency_injection/service_locator.dart';

final _appLinks = AppLinks();
String? _pendingDeepLink;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Step 1: Initialize Firebase ONCE
  await Firebase.initializeApp();

  // ✅ Step 2: Configure Firestore settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ✅ Step 3: Setup connectivity listener
  Connectivity().onConnectivityChanged.listen((result) {
    if (result != ConnectivityResult.none) {
      debugPrint('Network restored: $result - Triggering Firebase reconnect');
      FirebaseFirestore.instance.enableNetwork();
    }
  });

  // ✅ Step 4: Load .env file FIRST (CRITICAL FIX)
  await dotenv.load(fileName: ".env");

  // ✅ Step 5: Setup GetIt service locator (now can safely read API keys)
  await setupServiceLocator();

  // ✅ Step 6: Handle deep linking
  final initialLink = await _appLinks.getInitialLink();
  if (initialLink != null) {
    _pendingDeepLink = initialLink.toString();
  }

  // ✅ Step 7: Initialize app version
  await AppVersion.init();

  // ✅ Step 8: Run app with GetIt-managed dependencies
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<ThemeNotifier>()),
        BlocProvider(create: (context) => getIt<AuthBloc>()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.host == 'note' && uri.pathSegments.length == 1) {
        _pendingDeepLink = uri.toString();
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, ThemeNotifier notifier, child) {
        return MaterialApp(
          title: 'Infinity Notes',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: notifier.themeMode,
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final authBloc = context.read<AuthBloc>();
                if (authBloc.state is AuthStateUninitialized) {
                  debugPrint('🔥 Dispatching AuthEventInitialize from MyApp');
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
  }
}

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
        if (state is AuthStateNeedsEmailVerification) {
          final shouldVerify = await showWarningDialog(
            context: context,
            title: "Verification Pending",
            message: "Please verify your email to continue.",
            buttonText: "Verify Now",
          );
          if (shouldVerify == true) {
            context.read<AuthBloc>().add(const AuthEventShouldVerifyEmail());
          }
        }
        if (state is AuthStateLoggedOut && !state.isLoading) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      builder: (context, state) {
        debugPrint('🔍 Auth state: ${state.runtimeType}');
        if (state is AuthStateLoggedIn) {
          return const NotesView();
        } else if (state is AuthStateNavigateToVerifyEmail) {
          return const VerifyEmailView();
        } else if (state is AuthStateLoggedOut) {
          return const LoginView();
        } else if (state is AuthStateRegistering) {
          return const RegisterView();
        } else if (state is AuthStateForgotPassword && state.hasSentEmail) {
          return const LoginView();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}

void handleDeepLink(BuildContext context, Uri uri) {
  debugPrint('Deep link received: $uri');
  if (uri.host == 'note' && uri.pathSegments.length == 1) {
    final noteId = uri.pathSegments[0];
    final authBloc = BlocProvider.of<AuthBloc>(context);
    final currentState = authBloc.state;
    if (currentState is AuthStateLoggedIn) {
      Navigator.of(context).pushNamed(
        CreateUpdateNoteRoute,
        arguments: {'noteId': noteId, 'isEditing': true},
      );
    } else {
      showCustomRoutingDialog(
        context: context,
        title: "Login Required",
        content: "Please login to access this feature.",
        routeButtonText: "Login",
        onRoutePressed: () => authBloc.add(const AuthEventLogOut()),
        cancelButtonText: "Cancel",
      );
    }
  }
}

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
    textTheme: const TextTheme(bodySmall: TextStyle(color: Colors.black54)),
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
    textTheme: const TextTheme(bodySmall: TextStyle(color: Colors.white54)),
    dividerColor: Colors.white12,
    disabledColor: Colors.grey,
  );
}
