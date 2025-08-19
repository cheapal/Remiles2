import 'package:flutter/material.dart';
import 'choose_role.dart';
import 'splash.dart'; // Import the SplashScreen
import 'welcome.dart'; // Import the WelcomeScreen
import 'joiningoption.dart'; // Import the JoiningOption screen
import 'login_screen.dart'; // Import the new LoginScreen

void main() {
  // This is the single, correct entry point for your entire application.
  runApp(const MyApp());
}

// MyApp is the root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp provides the routing and navigation capabilities.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // The home property sets the first screen of the app.
      // The SplashScreen is now the entry point and is passed the WelcomeScreen as its next destination.
      // home:RoleSelectionScreen()
      home: SplashScreen(
        nextScreen: WelcomeScreen(
          // The WelcomeScreen's button will navigate to the JoiningOption screen.
          nextScreen: JoiningOption(
            // The JoiningOption's "Log In" button will navigate to the LoginScreen.
            nextScreen: const LoginScreen(),
          ),
        ),
      ),
    );
  }
}
