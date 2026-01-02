import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/firebase_service.dart';
import 'carrier_onboarding_2.dart';
import 'carrier_onboarding_4.dart'; // Import the next screen
import 'other_carrier_onboarding_3.dart'; // Import the "other" screen

class CarrierOnboarding3Screen extends StatefulWidget {
  final VoidCallback? onOnboardingComplete;
  const CarrierOnboarding3Screen({super.key, this.onOnboardingComplete});

  @override
  State<CarrierOnboarding3Screen> createState() =>
      _CarrierOnboarding3ScreenState();
}

class _CarrierOnboarding3ScreenState extends State<CarrierOnboarding3Screen> {
  // State variable to hold the currently selected options
  Set<String> _selectedOptions = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedResponses();
  }

  // Load saved responses for this screen
  Future<void> _loadSavedResponses() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier != null) {
        final onboardingData = await FirebaseService.getCarrierOnboardingData(
          carrier.uid,
        );
        if (onboardingData != null) {
          final response = onboardingData.getResponse(
            'onboarding_3_service_areas',
          );
          if (response != null && response['selectedOptions'] != null) {
            setState(() {
              _selectedOptions = Set<String>.from(response['selectedOptions']);
            });
          }
        }
      }
    } catch (e) {
      print('Error loading saved responses for onboarding 3: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // A custom page route to handle the fade transition
  PageRouteBuilder _createFadePageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
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

  // Save onboarding response for this screen
  Future<void> _saveOnboardingResponse() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier != null) {
        final response = {
          'selectedOptions': _selectedOptions.toList(),
          'timestamp': DateTime.now().toIso8601String(),
        };

        await FirebaseService.saveCarrierOnboardingResponse(
          carrier.uid,
          'onboarding_3_service_areas',
          response,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
              'Network timeout. Please check your internet connection.',
            );
          },
        );

        print('Onboarding 3 response saved: ${_selectedOptions.toList()}');
      }
    } catch (e) {
      print('Error saving onboarding 3 response: $e');
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
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFEFEF6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B744F)),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      );
    }

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
              if (!kIsWeb)
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

              if (kIsWeb)
                Positioned(
                  top: 176 * scale,
                  left: 46,
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
                  onTap: _isSaving
                      ? null
                      : () async {
                          if (_selectedOptions.isNotEmpty) {
                            // Save the response before proceeding
                            await _saveOnboardingResponse();

                            if (mounted) {
                              Navigator.push(
                                context,
                                _createFadePageRoute(
                                  CarrierOnboarding4Screen(
                                    onOnboardingComplete:
                                        widget.onOnboardingComplete,
                                  ),
                                ),
                              );
                            }
                          } else {
                            _showAlertDialog(
                              context,
                              'Please select at least one option to proceed.',
                            );
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
                      child: _isSaving
                          ? SizedBox(
                              width: 20 * scale,
                              height: 20 * scale,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
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
                color: isSelected
                    ? const Color(0xFF4B744F)
                    : const Color(0xFFF8F8F8),
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
                  ? Icon(Icons.check, color: Colors.white, size: 24 * scale)
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

  Widget _buildOtherButton(
    double scale,
    String text,
    double top,
    BuildContext context,
  ) {
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
