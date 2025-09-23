import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:majh/shipper_onboarding_2.dart';
import 'other_shipper_onboarding_1.dart'; // Import the new other screen
import 'shipper_signup.dart'; // Import the shipper signup screen

class ShipperOnboarding1Screen extends StatefulWidget {
  const ShipperOnboarding1Screen({super.key});

  @override
  State<ShipperOnboarding1Screen> createState() => _ShipperOnboarding1ScreenState();
}

class _ShipperOnboarding1ScreenState extends State<ShipperOnboarding1Screen> {
  // State variable to hold the currently selected vehicle types
  Set<String> _selectedFreightTypes = {};

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

  // A custom page route for smooth transitions
  PageRouteBuilder _createRoute(Widget nextScreen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // A helper function to show a simple AlertDialog
  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selection Required'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
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

              // Back button positioned at the top left
              Positioned(
                top: 50 * scale,
                left: 10 * scale,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.black,
                    size: 40 * scale,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      _createFadePageRoute(const ShipperSignUpScreen()),
                    );
                  },
                ),
              ),

              // Loading bar
              Positioned(
                top: 137 * scale,
                left: 52.5 * scale,
                child: Container(
                  width: 322.5 * scale,
                  height: 6 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(6 * scale),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 46.5 * scale),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, width, child) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: width,
                          height: 6 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFF597D5C),
                            borderRadius: BorderRadius.circular(6 * scale),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Title text
              Positioned(
                top: 183.5 * scale,
                left: 0,
                right: 20,
                child: Center(
                  child: Text(
                    'What type of freight do you typically \nship?',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
              ),

              // Freight Type Options
              _buildFreightOption(scale, 'General freight', 262.5 * scale),
              _buildFreightOption(scale, 'Refrigerated goods', 329.5 * scale),
              _buildFreightOption(scale, 'Construction materials', 396.5 * scale),
              _buildFreightOption(scale, 'Agriculture products', 463.5 * scale),
              _buildFreightOption(scale, 'Retail or packaged goods', 529.5 * scale),
              _buildFreightOption(scale, 'Hazardous materials', 592 * scale),

              // Other option as a button
              _buildOtherButton(scale, 'Other', 664 * scale, context),

              // Next button
              Positioned(
                top: 714 * scale,
                left: 287 * scale,
                child: GestureDetector(
                  onTap: () {
                    if (_selectedFreightTypes.isNotEmpty) {
                      Navigator.push(
                        context,
                        _createFadePageRoute(const ShipperOnboarding2Screen()),
                      );
                    } else {
                      _showAlertDialog(context, 'Please select at least one option to proceed.');
                    }
                  },
                  child: Container(
                    width: 110 * scale,
                    height: 55 * scale,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/signup_button.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(24.5)),
                    ),
                    child: Align(
                      alignment: const Alignment(0, -0.2),
                      child: Text(
                        "Next",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
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

  // Helper method to build a vehicle option
  Widget _buildFreightOption(double scale, String text, double top) {
    final isSelected = _selectedFreightTypes.contains(text);
    return Positioned(
      top: top,
      left: 50 * scale,
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Toggle selection
            if (isSelected) {
              _selectedFreightTypes.remove(text);
            } else {
              _selectedFreightTypes.add(text);
            }
          });
        },
        child: Row(
          children: [
            // The checkbox container
            Container(
              width: 34 * scale,
              height: 36 * scale,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4B744F) : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(5 * scale),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.25),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(
                Icons.check,
                color: Colors.white,
                size: 24 * scale,
              )
                  : null,
            ),
            SizedBox(width: 20 * scale),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the "Other" option as a button
  Widget _buildOtherButton(double scale, String text, double top, BuildContext context) {
    return Positioned(
      top: top,
      left: 50 * scale,
      child: GestureDetector(
        onTap: () {
          // Navigate to the new screen when "Other" is tapped
          Navigator.push(
            context,
            _createFadePageRoute(const OtherShipperOnboardingScreen()),
          );
        },
        child: Container(
          width: 156 * scale,
          height: 49 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(5 * scale),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 3,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF000000),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
