import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/firebase_service.dart';
import '../../providers/auth_provider.dart';
import 'shipper_onboarding_5.dart';
import 'shipper_onboarding_7.dart';

class ShipperOnboarding6Screen extends StatefulWidget {
  const ShipperOnboarding6Screen({super.key});

  @override
  State<ShipperOnboarding6Screen> createState() => _ShipperOnboarding6ScreenState();
}

class _ShipperOnboarding6ScreenState extends State<ShipperOnboarding6Screen> {
  String? _selectedOption;
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
      final response = data?.getResponse('screen6_tracking');
      if (response != null && response['selected'] is String) {
        _selectedOption = response['selected'] as String;
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
                      _createFadeRoute(const ShipperOnboarding5Screen()),
                    );
                  },
                ),
              ),
              Positioned(
                top: 141.5 * scale,
                left: 48.5 * scale,
                child: Container(
                  width: 322.5 * scale,
                  height: 6 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(6 * scale),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 268.75 * scale, end: 322.5 * scale),
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
                top: 188 * scale,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Do you track shipments in real time or \nonly after delivery?',
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
                    'Do you track shipments in real time or \nonly after delivery?',
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
              _buildRadioOption(scale, 'Real time', 282 * scale),
              _buildRadioOption(scale, 'After delivery', 349 * scale),
              _buildRadioOption(scale, 'Not Tracked', 415 * scale),
              Positioned(
                top: 627 * scale,
                left: 287 * scale,
                child: GestureDetector(
                  onTap: () async {
                    if (_selectedOption == null) {
                      _showAlertDialog(context, 'Please select an option to proceed.');
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
                          'screen6_tracking',
                          {
                            'selected': _selectedOption,
                          },
                        ).timeout(
                          const Duration(seconds: 10),
                          onTimeout: () {
                            throw Exception('Network timeout. Please check your internet connection.');
                          },
                        );
                      }
                      if (!mounted) return;
                      Navigator.push(context, _createFadeRoute(const ShipperOnboarding7Screen()));
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

  Widget _buildRadioOption(double scale, String text, double top) {
    final isSelected = _selectedOption == text;
    return Positioned(
      top: top,
      left: 49 * scale,
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
