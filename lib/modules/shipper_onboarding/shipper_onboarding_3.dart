import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/firebase_service.dart';
import '../../providers/auth_provider.dart';
import 'shipper_onboarding_2.dart';
import 'shipper_onboarding_4.dart';
import 'other_shipper_onboarding_3.dart';

class ShipperOnboarding3Screen extends StatefulWidget {
  const ShipperOnboarding3Screen({super.key});

  @override
  State<ShipperOnboarding3Screen> createState() => _ShipperOnboarding3ScreenState();
}

class _ShipperOnboarding3ScreenState extends State<ShipperOnboarding3Screen> {
  Set<String> _selectedOptions = {};
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
      final response = data?.getResponse('screen3_booking_methods');
      if (response != null && response['selected'] is List) {
        _selectedOptions = Set<String>.from(List<String>.from(response['selected']));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingPrefill = false);
  }

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
              Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFFEFEF6),
              ),
              if (_loadingPrefill)
                const Center(child: CircularProgressIndicator()),
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
                      _createFadeRoute(const ShipperOnboarding2Screen()),
                    );
                  },
                ),
              ),
              Positioned(
                top: 139 * scale,
                left: 48.5 * scale,
                child: Container(
                  width: 322.5 * scale,
                  height: 6 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(6 * scale),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 107.5 * scale, end: 161.25 * scale),
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
              
              if (!kIsWeb)
              Positioned(
                top: 186 * scale,
                left: 0,
                right: 25,
                child: Center(
                  child: Text(
                    'How do you currently book trucks or \npost loads?',
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
                    'How do you currently book trucks or \npost loads?',
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
              _buildCheckboxOption(scale, 'Phone calls', 275 * scale),
              _buildCheckboxOption(scale, 'Dispatchers', 342 * scale),
              _buildCheckboxOption(scale, 'Facebook Groups', 409 * scale),
              _buildCheckboxOption(scale, 'Kijiji', 476 * scale),
              _buildCheckboxOption(scale, 'Load Boards', 543 * scale),
              _buildOtherButton(scale, 'Other', 620 * scale, context),
              Positioned(
                top: 685 * scale,
                left: 287 * scale,
                child: GestureDetector(
                  onTap: () async {
                    if (_selectedOptions.isEmpty) {
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
                          'screen3_booking_methods',
                          {
                            'selected': _selectedOptions.toList(),
                          },
                        ).timeout(
                          const Duration(seconds: 10),
                          onTimeout: () {
                            throw Exception('Network timeout. Please check your internet connection.');
                          },
                        );
                      }
                      if (!mounted) return;
                      Navigator.push(context, _createFadeRoute(const ShipperOnboarding4Screen()));
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

  Widget _buildCheckboxOption(double scale, String text, double top) {
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
            _createFadeRoute(const OtherShipperOnboarding3()),
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
}
