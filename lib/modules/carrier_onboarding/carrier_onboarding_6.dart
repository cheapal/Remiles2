import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/firebase_service.dart';
import 'carrier_onboarding_5.dart';
import 'carrier_onboarding_7.dart'; // Import the next screen

class CarrierOnboarding6Screen extends StatefulWidget {
  final VoidCallback? onOnboardingComplete;
  const CarrierOnboarding6Screen({super.key, this.onOnboardingComplete});

  @override
  State<CarrierOnboarding6Screen> createState() => _CarrierOnboarding6ScreenState();
}

class _CarrierOnboarding6ScreenState extends State<CarrierOnboarding6Screen> {
  // Controller for the text field
  final TextEditingController _incomeController = TextEditingController();
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
          final response = onboardingData.getResponse('onboarding_6_income');
          if (response != null && response['incomeAmount'] != null) {
            setState(() {
              _incomeController.text = response['incomeAmount'];
            });
          }
        }
      }
    } catch (e) {
      print('Error loading saved responses for onboarding 6: $e');
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
          'incomeAmount': _incomeController.text.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        await FirebaseService.saveCarrierOnboardingResponse(
          carrier.uid,
          'onboarding_6_income',
          response,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Network timeout. Please check your internet connection.');
          },
        );
        
        print('Onboarding 6 response saved: ${_incomeController.text.trim()}');
      }
    } catch (e) {
      print('Error saving onboarding 6 response: $e');
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
    final double startWidth = 290 * scale;
    final double endWidth = 322.5 * scale;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents screen from resizing when keyboard opens
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
                    // Navigate back to the previous onboarding screen with a fade transition.
                    Navigator.pushReplacement(
                      context,
                      _createFadePageRoute(const CarrierOnboarding5Screen()),
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

              // Content Section (Title and Input Field)
              // This is wrapped in a SingleChildScrollView to prevent overflow
              // when the keyboard appears. The image and button will be fixed
              // in the stack.
              Positioned.fill(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 188 * scale),
                        Text(
                          'How much income do you estimate you \nlose per week from running empty?',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        SizedBox(height: 102 * scale),

                        // Text input field for income
                        SizedBox(
                          width: 255 * scale,
                          height: 49 * scale,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(5 * scale),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.25),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                              child: Row(
                                children: [
                                  // Bigger Dollar sign with space
                                  Text(
                                    '\$',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 25 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF38563B),
                                    ),
                                  ),
                                  SizedBox(width: 5 * scale),

                                  // Input field
                                  Expanded(
                                    child: TextField(
                                      controller: _incomeController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: TextStyle(
                                        fontSize: 24 * scale,
                                        fontWeight: FontWeight.bold,

                                        color: Colors.black,
                                      ),
                                      cursorColor: Colors.black,

                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 1 * scale),
                                        border: InputBorder.none,
                                        hintText: 'Enter amount (e.g., 0)',
                                        hintStyle: TextStyle(
                                          fontSize: 24 * scale,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Next button
              Positioned(
                top: 626 * scale,
                left: 287 * scale,
                child: GestureDetector(
                  onTap: _isSaving ? null : () async {
                    // Validate that user has entered an amount (including 0)
                    final incomeText = _incomeController.text.trim();
                    if (incomeText.isEmpty) {
                      _showAlertDialog(context, 'Please enter an income amount to proceed.');
                      return;
                    }
                    
                    // Validate that it's a valid number
                    final incomeValue = int.tryParse(incomeText);
                    if (incomeValue == null) {
                      _showAlertDialog(context, 'Please enter a valid number.');
                      return;
                    }
                    
                    // Save the response before proceeding
                    await _saveOnboardingResponse();
                    
                    if (mounted) {
                      Navigator.push(
                        context,
                        _createFadePageRoute(CarrierOnboarding7Screen(
                          onOnboardingComplete: widget.onOnboardingComplete,
                        )),
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
}
