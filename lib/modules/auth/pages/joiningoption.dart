import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'choose_role.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // We set SignScreen as the home screen to test it directly.
      home: const SignScreen(
        nextScreen: LoginScreen(),
      ),
    );
  }
}

// -------------------------------------------------------------------
// SIGN IN / SIGN UP SCREEN UI CODE (Moved here to fix the issue)
// -------------------------------------------------------------------

class SignScreen extends StatelessWidget {
  // This screen now requires a Widget to navigate to.
  final Widget nextScreen;

  const SignScreen({super.key, required this.nextScreen});

  // A custom page route to handle the fade transition
  PageRouteBuilder _createFadePageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons for Android
        statusBarBrightness: Brightness.dark,      // White icons for iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFEF6),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              /// Background leather image
              Positioned.fill(
                child: Image.asset(
                  'assets/leather.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                ),
              ),

              /// Sign In button
              Positioned(
                left: 74,
                right: 74,
                top: 525,
                child: AnimatedPressableContainer(
                  onTap: () {
                    // This now correctly navigates to the screen we passed in.
                    Navigator.of(context).push(
                      _createFadePageRoute(const LoginScreen()),
                    );
                  },
                  child: Container(
                    width: 281,
                    height: 49,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(24.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: "HelveticaRounded",
                        color: Color(0xFF113F29),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),

              /// Sign Up button
              Positioned(
                left: 74,
                right: 74,
                top: 598,
                child: AnimatedPressableContainer(
                  onTap: () {
                    // This navigates to the RoleSelectionScreen.
                    Navigator.of(context).push(
                      _createFadePageRoute(const RoleSelectionScreen()),
                    );
                  },
                  child: Container(
                    width: 281,
                    height: 49,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(24.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: "HelveticaRounded",
                        color: Color(0xFF144731),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),

              /// Remiles logo image
              Positioned(
                left: 0,
                right: 0,
                bottom: 320,
                child: Center(
                  child: SizedBox(
                    width: 230,
                    height: 320,
                    child: Image.asset(
                      'assets/remiles.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable pressable container with tap animation
class AnimatedPressableContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedPressableContainer({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  _AnimatedPressableContainerState createState() =>
      _AnimatedPressableContainerState();
}

class _AnimatedPressableContainerState
    extends State<AnimatedPressableContainer> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
