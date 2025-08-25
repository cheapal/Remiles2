import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'choose_role.dart';
import 'shipper_onboarding_1.dart'; // Import the new onboarding screen

class ShipperSignUpScreen extends StatefulWidget {
  const ShipperSignUpScreen({Key? key}) : super(key: key);

  @override
  State<ShipperSignUpScreen> createState() => _ShipperSignUpScreenState();
}

class _ShipperSignUpScreenState extends State<ShipperSignUpScreen> {
  // State for password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

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
      resizeToAvoidBottomInset: false, // Prevents screen from resizing
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark, // Changed to dark to make icons black
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Remiles Logo at the top
                    SizedBox(height: 40 * scale), // Top padding for the header
                    SizedBox(
                      width: 150 * scale,
                      height: 150 * scale,
                      child: Image.asset(
                        'assets/remiles.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Text(
                      'Shipper Sign up',
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    SizedBox(height: 31 * scale),

                    Container(
                      width: 330 * scale, // From XML: 330dp width
                      // Removed fixed height to allow content to dictate height
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFEF6),
                        // Background color from XML
                        borderRadius: BorderRadius.circular(
                            37 * scale), // Rounded corners like XML
                      ),
                      // Removed ScrollbarTheme and SingleChildScrollView
                      child: Column(
                        children: [
                          // 1. Company Name or Full Name
                          _buildInputField(
                            scale: scale,
                            hintText: "Company name or Full name",
                            iconAsset: 'assets/user.png',
                          ),
                          SizedBox(height: 25 * scale),

                          // 2. Email Address
                          _buildInputField(
                            scale: scale,
                            hintText: "Email Address",
                            iconAsset: 'assets/email.png',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 25 * scale),

                          // 3. Contact Number
                          _buildPhoneInputField(
                            scale: scale,
                            hintText: "Contact Number",
                          ),
                          SizedBox(height: 25 * scale),

                          // 4. Password
                          _buildInputField(
                            scale: scale,
                            hintText: "Password",
                            iconAsset: 'assets/password.png',
                            obscureText: _obscurePassword,
                            onSuffixIconPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          SizedBox(height: 25 * scale),

                          // 5. Confirm Password
                          _buildInputField(
                            scale: scale,
                            hintText: "Confirm Password",
                            iconAsset: 'assets/password.png',
                            obscureText: _obscureConfirmPassword,
                            onSuffixIconPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                              });
                            },
                          ),
                          SizedBox(height: 20 * scale),

                          // Terms and conditions
                          Container(
                            width: 294 * scale,
                            height: 45 * scale,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _agreeToTerms = !_agreeToTerms;
                                    });
                                  },
                                  child: Container(
                                    width: 20 * scale,
                                    height: 20 * scale,
                                    margin: EdgeInsets.only(
                                        right: 8 * scale, top: 2 * scale),
                                    decoration: BoxDecoration(
                                      color: _agreeToTerms
                                          ? const Color(0xFF4B744F)
                                          : Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(4 * scale),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color.fromRGBO(0, 0, 0, 0.25),
                                          blurRadius: 4,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _agreeToTerms
                                        ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14 * scale,
                                    )
                                        : null,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'I have read and agree to the Re-Miles Terms of Service, User Agreement, and Privacy Policy.',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12 * scale,
                                      height: 14 / 12,
                                      color: const Color(0xFF7D8AB0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Spacer(),
                  ],
                ),
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
                      _createFadePageRoute(const RoleSelectionScreen()),
                    );
                  },
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

              // Next Button - Fixed at the bottom right
              Positioned(
                bottom: 190 * scale,
                right: 30 * scale,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to the shipper onboarding screen
                    Navigator.push(
                      context,
                      _createFadePageRoute(const ShipperOnboarding1Screen()),
                    );
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
                    // Use Align to fine-tune the text position
                    child: Align(
                      // Shift the text up by a small amount
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
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a standardized input field
  Widget _buildInputField({
    required double scale,
    required String hintText,
    required String iconAsset,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSuffixIconPressed,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      width: 314 * scale,
      height: 60 * scale, // Increased height
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25), // Changed color to black
            blurRadius: 3,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Row(
          children: [
            // Left icon
            Image.asset(
              iconAsset,
              width: 15.71 * scale,
              height: 18 * scale,
              color: Colors.grey.withOpacity(0.5), // Changed color to faded grey
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: TextField(
                obscureText: obscureText,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 16 * scale,
                    color: const Color(0x40000000), // Changed color to faded grey
                  ),
                ),
                style: TextStyle(
                  fontSize: 16 * scale,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
            // Suffix icon for password fields
            if (onSuffixIconPressed != null)
              IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey, // Changed color to faded grey
                  size: 24 * scale,
                ),
                onPressed: onSuffixIconPressed,
              ),
          ],
        ),
      ),
    );
  }

  // Helper method for the phone number field with flag and country code
  Widget _buildPhoneInputField({required double scale, required String hintText}) {
    return Container(
      width: 314 * scale,
      height: 60 * scale, // Increased height
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10 * scale), // Rounded corners
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25), // Changed color to black
            blurRadius: 3,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Row(
          children: [
            // Canadian flag image
            Image.asset(
              'assets/canada_flag.png',
              width: 30 * scale,
              height: 20 * scale,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8 * scale),
            // Country code
            Text(
              '+1',
              style: TextStyle(
                fontSize: 16 * scale,
                color: const Color(0xFF000000),
              ),
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly // Allows only numbers
                ],
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 16 * scale,
                    color: const Color(0x40000000), // Changed color to faded grey
                  ),
                ),
                style: TextStyle(
                  fontSize: 16 * scale,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
