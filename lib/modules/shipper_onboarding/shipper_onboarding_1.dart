// import removed duplicate
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../core/firebase_service.dart';
import '../../providers/auth_provider.dart';
import 'shipper_onboarding_2.dart';
import 'other_shipper_onboarding_1.dart';
// use the absolute above import already present, remove duplicate relative

class ShipperOnboarding1Screen extends StatefulWidget {
  const ShipperOnboarding1Screen({super.key});

  @override
  State<ShipperOnboarding1Screen> createState() => _ShipperOnboarding1ScreenState();
}

class _ShipperOnboarding1ScreenState extends State<ShipperOnboarding1Screen> {
  // State variable to hold the currently selected vehicle types
  Set<String> _selectedFreightTypes = {};
  bool _loadingPrefill = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefillFromServer();
  }

  Future<void> _prefillFromServer() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;
      if (shipper == null) return setState(() => _loadingPrefill = false);
      final data = await FirebaseService.getShipperOnboardingData(shipper.uid);
      final response = data?.getResponse('screen1_freight_types');
      if (response != null && response['selected'] is List) {
        _selectedFreightTypes = Set<String>.from(List<String>.from(response['selected']));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingPrefill = false);
  }

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

  // removed unused _createRoute

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
              if (_loadingPrefill)
                const Center(child: CircularProgressIndicator()),
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
                    Navigator.of(context).maybePop();
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
              
              if (!kIsWeb)
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

              if (kIsWeb)
              Positioned(
                top: 180.5 * scale,
                left: 52 * scale,
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
                  onTap: () async {
                    if (_selectedFreightTypes.isEmpty) {
                      _showAlertDialog(context, 'Please select at least one option to proceed.');
                      return;
                    }
                    if (_saving) return;
                    
                    setState(() => _saving = true);
                    try {
                      final authProvider = context.read<AuthProvider>();
                      final shipper = authProvider.shipperUser;
                      if (shipper != null) {
                        await FirebaseService.saveShipperOnboardingResponse(
                          shipper.uid,
                          'screen1_freight_types',
                          {
                            'selected': _selectedFreightTypes.toList(),
                          },
                        ).timeout(
                          const Duration(seconds: 10),
                          onTimeout: () {
                            throw Exception('Network timeout. Please check your internet connection.');
                          },
                        );
                      }
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        _createFadePageRoute(const ShipperOnboarding2Screen()),
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
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
                      child: _saving
                          ? SizedBox(
                              width: 20 * scale,
                              height: 20 * scale,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
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