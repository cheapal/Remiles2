import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../shipper_dashboard/pages/shipper_dashboard_1.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShipperOnboarding7Screen extends StatefulWidget {
  const ShipperOnboarding7Screen({super.key});

  @override
  State<ShipperOnboarding7Screen> createState() => _ShipperOnboarding7ScreenState();
}

class _ShipperOnboarding7ScreenState extends State<ShipperOnboarding7Screen> {
  bool _completing = false;

  // Custom page route for a smooth fade transition
  PageRouteBuilder _createFadeRoute(Widget nextScreen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.ease;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return FadeTransition(
          opacity: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions to apply proportional scaling
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double designW = 456.0;
    const double designH = 952.0;
    final double scale = (screenWidth / designW < screenHeight / designH)
        ? screenWidth / designW
        : screenHeight / designH;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              // Main background and content
              Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFFEFEF6),
              ),

              // Re-miles logo at the top
              Positioned(
                top: 120 * scale,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/remiles.png',
                    width: 206 * scale,
                    height: 206 * scale,
                  ),
                ),
              ),

              // Title text with underline
              Positioned(
                top: 350 * scale, // Pushed down
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'You\'re All Set!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          letterSpacing: -1,
                          fontSize: 30 * scale,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF000000),
                        ),
                      ),

                      // Green divider line under the title
                      SizedBox(height: 18 * scale),
                      Container(
                        width: 324 * scale,
                        height: 4 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF113F29).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8 * scale),
                        ),
                      ),

                      SizedBox(height: 22 * scale),
                    ],
                  ),
                ),
              ),

              // Body text
              Positioned(
                top: 430 * scale, // Pushed down
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 388 * scale,
                    child: Text(
                      'Thanks for joining Re-Miles. You’re ready to start connecting with carriers, saving on shipping costs, and tracking your freight in real time. All in one platform.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16 * scale,
                        color: const Color(0xFF0B0B0B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Next button
              Positioned(
                top: 600 * scale, // Pushed down
                left: 0,
                right: 0,
                child: Center( // Centered horizontally
                  child: GestureDetector(
                    onTap: () async {
                      if (_completing) return;
                      
                      setState(() => _completing = true);
                      try {
                        final authProvider = context.read<AuthProvider>();
                        final shipper = authProvider.shipperUser;
                        if (shipper != null) {
                          await FirebaseService.markShipperOnboardingComplete(shipper.uid).timeout(
                            const Duration(seconds: 10),
                            onTimeout: () {
                              throw Exception('Network timeout. Please check your internet connection.');
                            },
                          );
                          // Update local provider state
                          authProvider.setUserData(
                            authProvider.firebaseUser,
                            shipper.copyWithShipper(
                              isOnboardingComplete: true,
                            ),
                          );
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          _createFadeRoute(const ShipperDashboard1()),
                          (route) => false,
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to complete onboarding: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _completing = false);
                      }
                    },
                    child: Container(
                      width: 290 * scale, // Increased dimensions
                      height: 70 * scale, // Increased dimensions
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/welcome_button.png'),
                          fit: BoxFit.fill,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10.5)),
                      ),
                      child: Align(
                        alignment: const Alignment(0, -0.2),
                        child: _completing
                            ? SizedBox(
                                width: 24 * scale,
                                height: 24 * scale,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                "See How Re-Miles Helps You",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.bold,
                                  shadows: const [
                                    Shadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.3),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom image positioned to touch the bottom and side edges
             
              if (!kIsWeb)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/leather_up.png',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
