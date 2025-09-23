import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'carrier_onboarding_2.dart';
import 'carrier_onboarding_4.dart'; // Import the next screen
import 'other_carrier_onboarding_3.dart'; // Import the "other" screen

class CarrierOnboarding3Screen extends StatefulWidget {
  const CarrierOnboarding3Screen({super.key});

  @override
  State<CarrierOnboarding3Screen> createState() => _CarrierOnboarding3ScreenState();
}

class _CarrierOnboarding3ScreenState extends State<CarrierOnboarding3Screen> {
  // State variable to hold the currently selected options
  Set<String> _selectedOptions = {};

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

    // Define the beginning and ending width of the loading bar fill
    final double startWidth = 104 * scale;
    final double endWidth = 170 * scale;

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
                      _createFadePageRoute(const CarrierOnboarding2Screen()),
                    );
                  },
                ),
              ),

              // Loading bar
              Positioned(
                top: 141.5 * scale,
                left: 48.5 * scale,
                right: 48.5 * scale,
                child: Container(
                  width: 322.5 * scale,
                  height: 6 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(6 * scale),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: startWidth, end: endWidth),
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
                top: 176 * scale,
                left: 0,
                right: 46,
                child: Center(
                  child: Text(
                    'How do you currently find loads?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
              ),

              // Options
              _buildOption(scale, 'Dispatcher', 235 * scale),
              _buildOption(scale, 'Load Boards', 302 * scale),
              _buildOption(scale, 'Facebook Groups', 369 * scale),
              _buildOption(scale, 'Kijiji', 436 * scale),
              _buildOption(scale, 'Word of mouth', 503 * scale),

              // Other option as a button
              _buildOtherButton(scale, 'Other', 580 * scale, context),

              // Next button
              Positioned(
                top: 625 * scale,
                left: 287 * scale,
                child: GestureDetector(
                  onTap: () {
                    if (_selectedOptions.isNotEmpty) {
                      Navigator.push(
                        context,
                        _createFadePageRoute(const CarrierOnboarding4Screen()),
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

  Widget _buildOption(double scale, String text, double top) {
    final isSelected = _selectedOptions.contains(text);
    return Positioned(
      top: top,
      left: 46 * scale,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedOptions.remove(text);
            } else {
              _selectedOptions.add(text);
            }
          });
        },
        child: Row(
          children: [
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

  Widget _buildOtherButton(double scale, String text, double top, BuildContext context) {
    return Positioned(
      top: top,
      left: 48 * scale,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            _createFadePageRoute(const OtherCarrierOnboarding3()),
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
