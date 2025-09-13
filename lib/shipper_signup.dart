import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'choose_role.dart';
import 'shipper_onboarding/shipper_onboarding_1.dart';

class ShipperSignUpScreen extends StatefulWidget {
  const ShipperSignUpScreen({Key? key}) : super(key: key);

  @override
  State<ShipperSignUpScreen> createState() => _ShipperSignUpScreenState();
}

class _ShipperSignUpScreenState extends State<ShipperSignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

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
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF6), // Consistent background
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use a threshold to switch between mobile and web layouts
          if (constraints.maxWidth > 900) {
            return _buildWebView(context);
          } else {
            return _buildMobileView(context);
          }
        },
      ),
    );
  }

  // Builds the split-screen UI for web/large screens
  Widget _buildWebView(BuildContext context) {
    return Row(
      children: [
        // Left side: Branding and inspirational content
        Expanded(
          flex: 1,
          child: _buildBrandingPanel(),
        ),
        // Right side: The sign-up form
        Expanded(
          flex: 1,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildSignUpForm(1.0, isWeb: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Builds the UI for mobile/small screens
  Widget _buildMobileView(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double designW = 456.0;
    const double designH = 952.0;
    final double scale = (screenWidth / designW < screenHeight / designH)
        ? screenWidth / designW
        : screenHeight / designH;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                child: _buildSignUpForm(scale, isWeb: false),
              ),
            ),
            // The leather image is only shown on mobile
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
    );
  }

  // Left branding panel for the web view
  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF059669)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(top: 100, right: 50, child: _buildCircle(60, Colors.white.withOpacity(0.05))),
          Positioned(bottom: 150, left: 40, child: _buildCircle(40, Colors.white.withOpacity(0.05))),
          Positioned(top: 300, left: 100, child: _buildCircle(25, Colors.white.withOpacity(0.05))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    const Text(
                      'Re-Miles',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Hero Text
                    const Text(
                      'Join Thousands of',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'Successful Shippers',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFA7F3D0),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connect with reliable carriers, streamline your logistics, and grow your shipping business with our platform.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Feature points
                    _buildFeaturePoint(Icons.shield_outlined, 'Secure & Reliable', 'End-to-end encrypted transactions'),
                    const SizedBox(height: 20),
                    _buildFeaturePoint(Icons.auto_awesome, 'Smart Matching', 'AI-powered carrier recommendations'),
                  ],
                ),
                const Spacer(), // Pushes the icon to the bottom
                // Carrier Icon
                Image.asset(
                  'assets/shipper_icon.png',
                  height: 320,
                  width: 320,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for decorative circles in branding panel
  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // Helper for feature points in branding panel
  Widget _buildFeaturePoint(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6EE7B7), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  // The main sign-up form, adapted for both web and mobile
  Widget _buildSignUpForm(double scale, {required bool isWeb}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isWeb) SizedBox(height: 40 * scale),

        // Back Button for Web
        if (isWeb)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.pushReplacement(context, _createFadePageRoute(const RoleSelectionScreen())),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(horizontal: 0),
              ),
            ),
          ),
        if (isWeb) const SizedBox(height: 24),

        // Header
        Align(
          alignment: isWeb ? Alignment.centerLeft : Alignment.center,
          child: Column(
            crossAxisAlignment: isWeb ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (!isWeb)
                Image.asset(
                  'assets/remiles.png',
                  width: 120 * scale,
                  height: 120 * scale,
                  fit: BoxFit.contain,
                ),
              Text(
                'Shipper Signup',
                style: TextStyle(
                  fontSize: isWeb ? 32 : 24 * scale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start your shipping journey with us today',
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14 * scale,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 40 * scale),

        // Form Fields
        _buildInputField(
          scale: scale,
          hintText: "Company name or Full name",
          icon: Icons.person_outline,
        ),
        SizedBox(height: 25 * scale),
        _buildInputField(
          scale: scale,
          hintText: "Email Address",
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 25 * scale),
        _buildPhoneInputField(scale: scale),
        SizedBox(height: 25 * scale),
        _buildInputField(
          scale: scale,
          hintText: "Password",
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          isPassword: true,
          onSuffixIconPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        SizedBox(height: 25 * scale),
        _buildInputField(
          scale: scale,
          hintText: "Confirm Password",
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          isPassword: true,
          onSuffixIconPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        SizedBox(height: 25 * scale),

        // Terms and Conditions
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _agreeToTerms,
                onChanged: (value) => setState(() => _agreeToTerms = value!),
                activeColor: const Color(0xFF059669),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'I have read and agree to the '),
                    _buildClickableTextSpan('Re-Miles Terms of Service'),
                    const TextSpan(text: ', '),
                    _buildClickableTextSpan('User Agreement'),
                    const TextSpan(text: ', and '),
                    _buildClickableTextSpan('Privacy Policy'),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 40 * scale),

        // Submit Button
        ElevatedButton(
          onPressed: _agreeToTerms && !_isLoading ? () {
            setState(() => _isLoading = true);
            Future.delayed(const Duration(seconds: 2), () {
              setState(() => _isLoading = false);
              Navigator.push(context, _createFadePageRoute(const ShipperOnboarding1Screen()));
            });
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            elevation: 2,
          ).copyWith(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) return Colors.grey;
                return const Color(0xFF059669);
              },
            ),
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Text("Create Account"),
        ),
        const SizedBox(height: 24),

        // Already have an account link
        Center(
          child: Text.rich(
            TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(color: Colors.grey[600]),
              children: [
                TextSpan(
                  text: 'Contact support to sign in',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    // Handle tap
                  },
                ),
              ],
            ),
          ),
        ),

        if (!isWeb) SizedBox(height: 220 * scale), // Padding for bottom image on mobile
      ],
    );
  }

  // Helper for clickable text in terms
  TextSpan _buildClickableTextSpan(String text) {
    return TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFF059669),
        fontWeight: FontWeight.w600,
      ),
      recognizer: TapGestureRecognizer()..onTap = () {
        // Handle navigation to terms/policy pages
      },
    );
  }

  // Updated input field with modern styling
  Widget _buildInputField({
    required double scale,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSuffixIconPressed,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onSuffixIconPressed,
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        hintStyle: TextStyle(fontSize: 14 * scale, color: Colors.grey[400]),
      ),
      style: TextStyle(fontSize: 14 * scale, color: Colors.black),
    );
  }

  // Updated phone input field
  Widget _buildPhoneInputField({required double scale}) {
    return TextFormField(
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: "(555) 123-4567",
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/canada_flag.png', width: 24, height: 16),
              const SizedBox(width: 8),
              const Text('+1', style: TextStyle(fontSize: 14, color: Colors.black)),
              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: Colors.grey[300]),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        hintStyle: TextStyle(fontSize: 14 * scale, color: Colors.grey[400]),
      ),
      style: TextStyle(fontSize: 14 * scale, color: Colors.black),
    );
  }
}
