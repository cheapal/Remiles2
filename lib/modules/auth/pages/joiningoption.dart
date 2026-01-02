import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'choose_role.dart';

// -------------------------------------------------------------------
// SIGN IN / SIGN UP SCREEN UI CODE
// -------------------------------------------------------------------

class SignScreen extends StatelessWidget {
  // This screen now requires a Widget to navigate to.
  final Widget nextScreen;
  final VoidCallback? onOnboardingComplete;

  const SignScreen({
    super.key,
    required this.nextScreen,
    this.onOnboardingComplete,
  });

  // A custom page route to handle the fade transition
  PageRouteBuilder _createFadePageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons for Android
        statusBarBrightness: Brightness.dark, // White icons for iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFEF6),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 676;
              if (isWide) {
                // Web: two-column layout with leather background on the left and controls on the right
                return Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            /// Remiles logo image
                            Center(
                              child: SizedBox(
                                width: 200, // Smaller width
                                height: 200, // Smaller height
                                child: Image.asset(
                                  'assets/remiles.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    _createFadePageRoute(const LoginScreen()),
                                  );
                                }
                              },
                              child: Container(
                                width: 320,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 3),
                                    ),
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
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    _createFadePageRoute(
                                      RoleSelectionScreen(
                                        onOnboardingComplete:
                                            onOnboardingComplete,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 320,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 3),
                                    ),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile layout (existing, preserved)
                return Stack(
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
                      child: GestureDetector(
                        onTap: () {
                          if (context.mounted) {
                            Navigator.of(
                              context,
                            ).push(_createFadePageRoute(const LoginScreen()));
                          }
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
                              ),
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
                      top: 590,
                      child: GestureDetector(
                        onTap: () {
                          if (context.mounted) {
                            Navigator.of(context).push(
                              _createFadePageRoute(
                                RoleSelectionScreen(
                                  onOnboardingComplete: onOnboardingComplete,
                                ),
                              ),
                            );
                          }
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
                              ),
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
                      top: 300, // Positioned at the top instead of bottom
                      child: Center(
                        child: SizedBox(
                          width: 200, // Smaller width
                          height: 200, // Smaller height
                          child: Image.asset(
                            'assets/remiles.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
