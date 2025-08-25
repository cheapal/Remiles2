import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'joiningoption.dart'; // Import the JoiningOption screen

class WelcomeScreen extends StatefulWidget {
  final Widget nextScreen;

  const WelcomeScreen({super.key, required this.nextScreen});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController for the waving animation
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000), // 1 second for one wave cycle
      vsync: this,
    );

    // Define the animation. The wave effect will be a slight rotation.
    _waveAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation and make it repeat for a duration of 2 seconds
    _waveController.repeat(reverse: true);
    Timer(const Duration(milliseconds: 2000), () {
      _waveController.stop();
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  // A custom page route to handle the slide transition
  PageRouteBuilder _createSlidePageRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFFFFFEF6),
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Aligns content vertically
                  children: [
                    // Top Image (Wave) with fixed sizing
                    AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _waveAnimation.value * math.pi, // Rotate in radians
                          child: child,
                        );
                      },
                      child: Container(
                        width: 123,
                        height: 123,
                        child: Image.asset(
                          "assets/welcome_wave.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Welcome text with responsive sizing.
                    // The 'fontFamily' has been updated to use the new font.
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                      child: const Text(
                        "Welcome\n to Re-Miles",
                        style: TextStyle(
                          color: Colors.black, // Black fill
                          fontSize: 48,
                          fontFamily: "RobotoFlex", // Using the specified font
                          letterSpacing: -1,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    // Description text with responsive padding
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                      child: const Text(
                        "Your all-in-one freight matching solution that connects carriers and shippers while seamlessly optimizing routes, maximizing earnings, and boosting efficiency in the freight industry.",
                        style: TextStyle(
                          color: Color(0xFF000000),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    // Get Started button with responsive sizing and local image
                    GestureDetector(
                      onTapDown: (details) {
                        setState(() {
                          _scale = 0.95;
                        });
                      },
                      onTapUp: (details) {
                        setState(() {
                          _scale = 1.0;
                        });
                      },
                      onTap: () {
                        // Navigate to the next screen with the custom slide transition.
                        Navigator.push(
                          context,
                          _createSlidePageRoute(),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        transform: Matrix4.identity()..scale(_scale),
                        width: 240,
                        height: 55,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          image: DecorationImage(
                            image: AssetImage("assets/welcome_button.png"),
                            // The `BoxFit.fill` property ensures the image stretches to fit the container's specified
                            // width and height exactly, preventing any parts of the image from being cut off.
                            fit: BoxFit.fill,
                          ),

                        ),
                        child: const Align(
                          // Shift the text up by a small amount
                          alignment: Alignment(0, -0.2),
                          child: Text(
                            "Get Started",
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Keep Calm",
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),
                  ],

                )
            ),
          ),
        ),
      ),
    );
  }
}
