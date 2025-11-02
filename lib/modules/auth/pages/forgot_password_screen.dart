import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_state_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final appStateProvider = context.read<AppStateProvider>();

    appStateProvider.showLoadingWithMessage('Sending reset email...');

    final success = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (success) {
      appStateProvider.showSuccess();
      setState(() {
        _isEmailSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Please check your inbox.'),
          backgroundColor: Color(0xFF4B744F),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      appStateProvider.showError(authProvider.errorMessage ?? 'Failed to send reset email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // The XML is based on a design width of 456dp and height of 952dp.
    // We'll use a proportional scaling factor to adapt to different screen sizes.
    const double designW = 456.0;
    const double designH = 952.0;
    final double scale = (screenWidth / designW < screenHeight / designH)
        ? screenWidth / designW
        : screenHeight / designH;

    return Consumer2<AuthProvider, AppStateProvider>(
      builder: (context, authProvider, appStateProvider, child) {
        return Scaffold(
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Leather Image
                            SizedBox(
                              width: double.infinity,
                              height: 250 * scale,
                              child: Image.asset(
                                'assets/leather.png',
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                            // Remiles Logo
                            SizedBox(height: 1 * scale),
                            SizedBox(
                              width: 280 * scale * 1,
                              height: 153 * scale * 1,
                              child: Image.asset(
                                'assets/remileswithtag.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 61 * scale),

                            // Title
                            Text(
                              _isEmailSent ? "Check Your Email" : "Forgot Password?",
                              style: TextStyle(
                                fontSize: 24 * scale,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF000000),
                              ),
                            ),
                            SizedBox(height: 10 * scale),

                            // Description
                            Container(
                              width: 314 * scale,
                              margin: EdgeInsets.symmetric(horizontal: (456 - 314) / 2 * scale),
                              child: Text(
                                _isEmailSent
                                    ? "We've sent a password reset link to your email address. Please check your inbox and follow the instructions."
                                    : "Enter your email address and we'll send you a link to reset your password.",
                                style: TextStyle(
                                  fontSize: 14 * scale,
                                  color: const Color(0x61000000),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 40 * scale),

                            if (!_isEmailSent) ...[
                              // Email Field
                              Container(
                                width: 314 * scale,
                                height: 49 * scale,
                                margin: EdgeInsets.symmetric(horizontal: (456 - 314) / 2 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(24.5 * scale),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x40000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24.5 * scale),
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    cursorColor: Colors.black,
                                    enabled: !authProvider.isLoading,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Email Address",
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
                              ),
                              SizedBox(height: 20 * scale),

                              // Error message display
                              if (authProvider.errorMessage != null)
                                Container(
                                  width: 314 * scale,
                                  margin: EdgeInsets.symmetric(horizontal: (456 - 314) / 2 * scale),
                                  padding: EdgeInsets.all(12 * scale),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8 * scale),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14 * scale,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              if (authProvider.errorMessage != null) SizedBox(height: 10 * scale),

                              // Send Reset Email Button
                              GestureDetector(
                                onTap: _handlePasswordReset,
                                child: Container(
                                  width: 314 * scale,
                                  height: 59 * scale,
                                  decoration: BoxDecoration(
                                    image: const DecorationImage(
                                      image: AssetImage('assets/login_button.png'),
                                      fit: BoxFit.fill,
                                    ),
                                    borderRadius: BorderRadius.circular(24.5 * scale),
                                  ),
                                  child: Align(
                                    alignment: Alignment(0, -0.2),
                                    child: authProvider.isLoading
                                        ? SizedBox(
                                            width: 20 * scale,
                                            height: 20 * scale,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            "Send Reset Link",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16 * scale,
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
                            ] else ...[
                              // Back to Login Button
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: 314 * scale,
                                  height: 59 * scale,
                                  decoration: BoxDecoration(
                                    image: const DecorationImage(
                                      image: AssetImage('assets/login_button.png'),
                                      fit: BoxFit.fill,
                                    ),
                                    borderRadius: BorderRadius.circular(24.5 * scale),
                                  ),
                                  child: Align(
                                    alignment: Alignment(0, -0.2),
                                    child: Text(
                                      "Back to Login",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16 * scale,
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
                            ],
                            SizedBox(height: 20 * scale),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Back Button
                  Positioned(
                    top: 170 * scale,
                    left: 20 * scale,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF4B744F),
                        size: 54 * scale,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

