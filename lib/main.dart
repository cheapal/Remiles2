import 'package:remiles/modules/auth/pages/login_screen.dart';
import 'package:remiles/modules/carrier_onboarding/carrier_signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'core/firebase_service.dart';
import 'core/app_config.dart';
import 'core/stripe_service.dart';
import 'package:provider/provider.dart';
import 'modules/auth/pages/choose_role.dart';
import 'firebase_options.dart';
import 'core/auth_wrapper.dart';
import 'core/app_check_wrapper.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/payment_methods_provider.dart';
import 'providers/carrier_payments_provider.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Firebase Analytics according to official docs
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(AppConfig.enableAnalytics);
      
      // Set session timeout (30 minutes) - only on non-web platforms
      if (!kIsWeb) {
        await analytics.setSessionTimeoutDuration(const Duration(minutes: 30));
      }
      
      if (AppConfig.enableDebugLogging) {
        print('Firebase Analytics initialized successfully');
        print('Analytics collection enabled: ${AppConfig.enableAnalytics}');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Firebase Analytics initialization failed: $e');
      }
    }
    
    // Initialize Firebase Crashlytics according to official docs
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      // Crashlytics is not fully supported on Web; guard initialization there
      if (!kIsWeb) {
        await crashlytics.setCrashlyticsCollectionEnabled(AppConfig.enableCrashlytics);
        // Set user identifier for better crash reporting (web guarded)
        await crashlytics.setUserIdentifier('app_user_${DateTime.now().millisecondsSinceEpoch}');
      }
      
      if (AppConfig.enableDebugLogging) {
        print('Firebase Crashlytics initialized successfully');
        print('Crashlytics collection enabled: ${AppConfig.enableCrashlytics}');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Firebase Crashlytics initialization failed: $e');
      }
    }
    
    // Initialize Stripe
    try {
      await StripeService.initialize();
      if (AppConfig.enableDebugLogging) {
        print('Stripe initialized successfully');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Stripe initialization error: $e');
      }
    }
    
    // Initialize Notification Service
    try {
      await NotificationService().initialize();
      if (AppConfig.enableDebugLogging) {
        print('Notification service initialized successfully');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Notification service initialization error: $e');
      }
    }
    
    // Test analytics and crashlytics only in debug mode
    if (AppConfig.enableTestEvents) {
      print('${AppConfig.versionInfo} - Running analytics test...');
      await FirebaseService.testAnalytics();
      
      print('${AppConfig.versionInfo} - Checking crashlytics health...');
      final isCrashlyticsWorking = await FirebaseService.isCrashlyticsWorking();
      if (isCrashlyticsWorking) {
        print('Crashlytics is working properly');
        print('${AppConfig.versionInfo} - Running crashlytics test...');
        await FirebaseService.testCrashlytics();
      } else {
        print('Crashlytics health check failed');
      }
    }
    
    // Set up error handlers
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
  } catch (e) {
    if (AppConfig.enableDebugLogging) {
      print('Firebase initialization error: $e');
    }
  }
  
  // The main function is the entry point for all Flutter apps.
  // It calls the runApp() function, which takes the root widget of the app.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Manual test logging disabled - Crashlytics is now working
    if (AppConfig.enableTestEvents) {
      FirebaseService.manualCrashlyticsTest();
      FirebaseService.isCrashlyticsWorking();
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => PaymentMethodsProvider()),
        ChangeNotifierProvider(create: (_) => CarrierPaymentsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AppCheckWrapper(),
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

