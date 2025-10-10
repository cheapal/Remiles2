import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'carrier_onboarding_1.dart'; // Import the new onboarding screen

class CarrierSignUpScreen extends StatefulWidget {
  const CarrierSignUpScreen({Key? key}) : super(key: key);

  @override
  State<CarrierSignUpScreen> createState() => _CarrierSignUpScreenState();
}

class _CarrierSignUpScreenState extends State<CarrierSignUpScreen> {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isWeb = kIsWeb;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    final isMobile = screenWidth <= 768;

    if (isWeb && isDesktop) {
      return _buildWebDesktopLayout(context, screenWidth, screenHeight);
    } else if (isWeb && isTablet) {
      return _buildWebTabletLayout(context, screenWidth, screenHeight);
    } else {
      return _buildMobileLayout(context, screenWidth, screenHeight);
    }
  }

  Widget _buildWebDesktopLayout(BuildContext context, double screenWidth, double screenHeight) {
    return Scaffold(
      body: Row(
        children: [
          // Left side - Welcome section with gradient background
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4B744F),
                    Color(0xFF6B8E6F),
                    Color(0xFF8BA88F),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: 100,
                    left: 50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 150,
                    right: 80,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Main content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/remiles.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Welcome text
                          const Text(
                            'Welcome to\nRe-Miles',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Join our network of trusted carriers and start your journey with us today.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Feature highlights
                          _buildFeatureItem('✓', 'Secure and reliable platform'),
                          const SizedBox(height: 15),
                          _buildFeatureItem('✓', 'Easy onboarding process'),
                          const SizedBox(height: 15),
                          _buildFeatureItem('✓', '24/7 customer support'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right side - Sign up form
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFFEFEF6),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(60.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.black,
                              size: 32,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000000),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign up to get started',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7D8AB0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        // Form fields
                        _buildWebInputField(
                          hintText: "Company name or Full name",
                          iconAsset: 'assets/user.png',
                        ),
                        const SizedBox(height: 20),
                        _buildWebInputField(
                          hintText: "Email Address",
                          iconAsset: 'assets/email.png',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _buildWebPhoneInputField(
                          hintText: "Contact Number",
                        ),
                        const SizedBox(height: 20),
                        _buildWebInputField(
                          hintText: "Password",
                          iconAsset: 'assets/password.png',
                          obscureText: _obscurePassword,
                          onSuffixIconPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildWebInputField(
                          hintText: "Confirm Password",
                          iconAsset: 'assets/password.png',
                          obscureText: _obscureConfirmPassword,
                          onSuffixIconPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        const SizedBox(height: 25),
                        // Terms and conditions
                        _buildWebTermsCheckbox(),
                        const SizedBox(height: 30),
                        // Sign up button
                        _buildWebSignUpButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTabletLayout(BuildContext context, double screenWidth, double screenHeight) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4B744F),
              Color(0xFFFEFEF6),
            ],
            stops: [0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/remiles.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome to Re-Miles',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form section
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFEF6),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildWebInputField(
                        hintText: "Company name or Full name",
                        iconAsset: 'assets/user.png',
                      ),
                      const SizedBox(height: 20),
                      _buildWebInputField(
                        hintText: "Email Address",
                        iconAsset: 'assets/email.png',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildWebPhoneInputField(
                        hintText: "Contact Number",
                      ),
                      const SizedBox(height: 20),
                      _buildWebInputField(
                        hintText: "Password",
                        iconAsset: 'assets/password.png',
                        obscureText: _obscurePassword,
                        onSuffixIconPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildWebInputField(
                        hintText: "Confirm Password",
                        iconAsset: 'assets/password.png',
                        obscureText: _obscureConfirmPassword,
                        onSuffixIconPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 25),
                      _buildWebTermsCheckbox(),
                      const SizedBox(height: 30),
                      _buildWebSignUpButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, double screenWidth, double screenHeight) {
    const double designW = 456.0;
    const double designH = 952.0;
    final double scale = (screenWidth / designW < screenHeight / designH)
        ? screenWidth / designW
        : screenHeight / designH;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 40 * scale),
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
                      'Carrier Sign up',
                      style: TextStyle(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    SizedBox(height: 31 * scale),
                    Container(
                      width: 330 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFEF6),
                        borderRadius: BorderRadius.circular(37 * scale),
                      ),
                      child: Column(
                        children: [
                          _buildInputField(
                            scale: scale,
                            hintText: "Company name or Full name",
                            iconAsset: 'assets/user.png',
                          ),
                          SizedBox(height: 25 * scale),
                          _buildInputField(
                            scale: scale,
                            hintText: "Email Address",
                            iconAsset: 'assets/email.png',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 25 * scale),
                          _buildPhoneInputField(
                            scale: scale,
                            hintText: "Contact Number",
                          ),
                          SizedBox(height: 25 * scale),
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
                          _buildInputField(
                            scale: scale,
                            hintText: "Confirm Password",
                            iconAsset: 'assets/password.png',
                            obscureText: _obscureConfirmPassword,
                            onSuffixIconPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          SizedBox(height: 20 * scale),
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
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 4,
                                          offset: const Offset(0, 4),
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
                    const Spacer(),
                  ],
                ),
              ),
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
              Positioned(
                bottom: 190 * scale,
                right: 30 * scale,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      _createFadePageRoute(const CarrierOnboarding1Screen()),
                    );
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
                    child: const Align(
                      alignment: Alignment(0, -0.2),
                      child: Text(
                        "Next",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebInputField({
    required String hintText,
    required String iconAsset,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSuffixIconPressed,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              width: 20,
              height: 20,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                obscureText: obscureText,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            if (onSuffixIconPressed != null)
              IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
                onPressed: onSuffixIconPressed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPhoneInputField({required String hintText}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Image.asset(
              'assets/canada_flag.png',
              width: 24,
              height: 16,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              '+1',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _agreeToTerms = !_agreeToTerms;
            });
          },
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: _agreeToTerms ? const Color(0xFF4B744F) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _agreeToTerms ? const Color(0xFF4B744F) : const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: _agreeToTerms
                ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            )
                : null,
          ),
        ),
        const Expanded(
          child: Text(
            'I have read and agree to the Re-Miles Terms of Service, User Agreement, and Privacy Policy.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            _createFadePageRoute(const CarrierOnboarding1Screen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4B744F),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
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
      height: 60 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0x40000000),
            blurRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              width: 15.71 * scale,
              height: 18 * scale,
              color: const Color(0x40000000),
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
                    color: const Color(0x40000000),
                  ),
                ),
                style: TextStyle(
                  fontSize: 16 * scale,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
            if (onSuffixIconPressed != null)
              IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
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
      height: 60 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0x40000000),
            blurRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Row(
          children: [
            Image.asset(
              'assets/canada_flag.png',
              width: 30 * scale,
              height: 20 * scale,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8 * scale),
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
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 16 * scale,
                    color: const Color(0x40000000),
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
