import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShipperOnboarding7Screen extends StatelessWidget {
  const ShipperOnboarding7Screen({super.key});

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
                    onTap: () {
                      // TODO: Add navigation to the next screen (e.g., home screen)
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
                        child: Text(
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
