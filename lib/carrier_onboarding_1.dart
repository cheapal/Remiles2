import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'other_button_screen.dart';
import 'carrier_onboarding_2.dart'; // Import the next screen

class CarrierOnboarding1Screen extends StatefulWidget {
  const CarrierOnboarding1Screen({super.key});

  @override
  State<CarrierOnboarding1Screen> createState() => _CarrierOnboarding1ScreenState();
}

class _CarrierOnboarding1ScreenState extends State<CarrierOnboarding1Screen> {
  // State variable to hold the currently selected vehicle types
  Set<String> _selectedVehicleTypes = {};

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
    final double endWidth = 46.5 * scale;

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
                    Navigator.of(context).pop();
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
                    tween: Tween<double>(begin: 0.0, end: endWidth),
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
                top: 190.5 * scale,
                left: 0,
                right: 17,
                child: Center(
                  child: Text(
                    'What type of vehicle do you operate?',
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

              // Vehicle Type Options
              _buildVehicleOption(scale, 'Dry Van', 252.5 * scale),
              _buildVehicleOption(scale, 'Reefer ( Refrigerated )', 319.5 * scale),
              _buildVehicleOption(scale, 'Flatbed', 386.5 * scale),
              _buildVehicleOption(scale, 'Boxtruck', 453.5 * scale),
              _buildVehicleOption(scale, 'Tanker', 519.5 * scale),

              // Other option as a button
              _buildOtherButton(scale, 'Other', 565.5 * scale, context),

              // Next button
              Positioned(
                top: 644 * scale,
                left: 287 * scale,
                child: GestureDetector(
                  onTap: () {
                    if (_selectedVehicleTypes.isNotEmpty) {
                      Navigator.push(
                        context,
                        _createFadePageRoute(const CarrierOnboarding2Screen()),
                      );
                    } else {
                      _showAlertDialog(context, 'Please select at least one option to proceed.');
                    }
                  },
                  child: Container(
                    width: 110 * scale,
                    height: 55 * scale,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/signup_button.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(24.5 * scale),
                    ),
                    child: Align(
                      alignment: Alignment(0, -0.2),
                      child: Text(
                        "Next",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
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
  Widget _buildVehicleOption(double scale, String text, double top) {
    final isSelected = _selectedVehicleTypes.contains(text);
    return Positioned(
      top: top,
      left: 50 * scale,
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Toggle selection
            if (isSelected) {
              _selectedVehicleTypes.remove(text);
            } else {
              _selectedVehicleTypes.add(text);
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
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
      top: top+20,
      left: 50 * scale,
      child: GestureDetector(
        onTap: () {
          // Navigate to the new screen when "Other" is tapped
          Navigator.push(
            context,
            _createFadePageRoute(const OtherButtonScreen()),
          );
        },
        child: Container(
          width: 156 * scale,
          height: 49 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(5 * scale),
            boxShadow: [
              BoxShadow(
                color: const Color(0x40000000),
                blurRadius: 3,
                offset: const Offset(0, 4),
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
