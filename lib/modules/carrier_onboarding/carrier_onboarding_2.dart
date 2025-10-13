import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/firebase_service.dart';
import 'other_carrier_onboarding_2.dart';
import 'carrier_onboarding_3.dart';

class CarrierOnboarding2Screen extends StatefulWidget {
  final VoidCallback? onOnboardingComplete;
  const CarrierOnboarding2Screen({super.key, this.onOnboardingComplete});

  @override
  State<CarrierOnboarding2Screen> createState() => _CarrierOnboarding2ScreenState();
}

class _CarrierOnboarding2ScreenState extends State<CarrierOnboarding2Screen> {
  // State variable to hold the currently selected option
  String? _selectedOption;
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
        final onboardingData = await FirebaseService.getCarrierOnboardingData(carrier.uid);
        if (onboardingData != null) {
          final response = onboardingData.getResponse('onboarding_2_business_type');
          if (response != null && response['selectedOption'] != null) {
            setState(() {
              _selectedOption = response['selectedOption'];
            });
          }
        }
      }
    } catch (e) {
      print('Error loading saved responses for onboarding 2: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Custom page route for a smooth fade transition
  PageRouteBuilder _createFadePageRoute(Widget nextScreen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
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
          'selectedOption': _selectedOption,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        await FirebaseService.saveCarrierOnboardingResponse(
          carrier.uid,
          'onboarding_2_business_type',
          response,
        );
        
        print('Onboarding 2 response saved: $_selectedOption');
      }
    } catch (e) {
      print('Error saving onboarding 2 response: $e');
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
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
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
    final double startWidth = 46.5 * scale;
    final double endWidth = 104 * scale;

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

              // Loading bar with animation
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

              // Title text aligned with the options
              Positioned(
                top: 194 * scale,
                left: 46 * scale, // Aligned with the checkboxes
                child: Text(
                  'How often are you looking to accept \nloads through the app?',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),

              // Options
              _buildOption(scale, 'full-time carrier/owner-operator — this is my primary work', 293 * scale),
              _buildOption(scale, 'I drive part-time or when I’m available', 360 * scale),
              _buildOption(scale, 'I’m just exploring the app right now', 427 * scale),

              // Other option as a button
              _buildOtherButton(scale, 'Other', 514 * scale, context),

              // Next button
              Positioned(
                top: 602 * scale,
                left: 287 * scale,
                child: GestureDetector(
                  onTap: _isSaving ? null : () async {
                    if (_selectedOption != null) {
                      // Save the response before proceeding
                      await _saveOnboardingResponse();
                      
                      if (mounted) {
                        Navigator.push(
                          context,
                          _createFadePageRoute(CarrierOnboarding3Screen(
                            onOnboardingComplete: widget.onOnboardingComplete,
                          )),
                        );
                      }
                    } else {
                      _showAlertDialog(context, 'Please select an option to proceed.');
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    final isSelected = _selectedOption == text;
    return Positioned(
      top: top,
      left: 46 * scale,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOption = text;
          });
        },
        child: Row(
          children: [
            Container(
              width: 34 * scale,
              height: 36 * scale,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4B744F) : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(20 * scale),
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
            SizedBox(
              width: 301 * scale,
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
                ),
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
      left: 50 * scale,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            _createFadePageRoute(const OtherCarrierOnboarding2()),
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
