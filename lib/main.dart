import 'package:Remiles/modules/auth/pages/login_screen.dart';
import 'package:Remiles/modules/carrier_onboarding/carrier_signup.dart';
import 'package:Remiles/modules/auth/pages/splash.dart';
import 'package:Remiles/modules/auth/pages/welcome.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'modules/auth/pages/choose_role.dart';
import 'modules/auth/pages/joiningoption.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
       // The home property sets the first screen of the app.
      // The SplashScreen is now the entry point and is passed the WelcomeScreen as its next destination.
     // home:RoleSelectionScreen()
      home: SplashScreen(
        nextScreen: WelcomeScreen(
          // The WelcomeScreen's button will navigate to the JoiningOption screen.
          nextScreen: SignScreen(
            // The JoiningOption's "Log In" button will navigate to the LoginScreen.
            nextScreen: const LoginScreen(),
          ),
        ),
      ),
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
    //  home: const ShipperDashboardMainPage(),
    );
  }
}

