import 'package:Remiles/modules/auth/pages/login_screen.dart';
import 'package:Remiles/modules/carrier_onboarding/carrier_signup.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'core/firebase_service.dart';
import 'core/app_config.dart';
import 'package:provider/provider.dart';
import 'modules/auth/pages/choose_role.dart';
import 'firebase_options.dart';
import 'core/auth_wrapper.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/app_state_provider.dart';

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Analytics
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(AppConfig.enableAnalytics);
  
  // Test analytics only in debug mode
  if (AppConfig.enableTestEvents) {
    print('${AppConfig.versionInfo} - Running analytics test...');
    await FirebaseService.testAnalytics();
  }
  
  // Initialize Firebase Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  // The main function is the entry point for all Flutter apps.
  // It calls the runApp() function, which takes the root widget of the app.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup/carrier': (context) => const CarrierSignUpScreen(),
          '/roleselection': (context) => const RoleSelectionScreen(),
        },
        title: 'Remiles App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
      ),
    );
  }
}

