import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../core/auth_wrapper.dart';
import '../../../models/user_model.dart';
import '../../shipper_dashboard/pages/shipper_dashboard_4_main_page.dart';
import '../../carrier_onboarding/carrier_onboarding_wrapper.dart';
import 'forgot_password_screen.dart';
import 'google_role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool _obscurePassword = true;
  
  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final appStateProvider = context.read<AppStateProvider>();

    appStateProvider.showLoadingWithMessage('Signing in...');

    final success = await authProvider.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      appStateProvider.showSuccess();
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful! Redirecting...'),
          backgroundColor: Color(0xFF4B744F),
          duration: Duration(seconds: 2),
        ),
      );
      
      print('Login successful, navigating based on user role');
      
      // Add a small delay to ensure user data is fully loaded
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Direct navigation as fallback if AuthWrapper doesn't trigger
      if (context.mounted) {
        _navigateBasedOnRole(context, authProvider);
      }
    } else {
      print('Login failed: ${authProvider.errorMessage}');
      appStateProvider.showError(authProvider.errorMessage ?? 'Login failed');
    }
  }

  // Handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final appStateProvider = context.read<AppStateProvider>();

    appStateProvider.showLoadingWithMessage('Signing in with Google...');

    final success = await authProvider.signInWithGoogle();

    appStateProvider.clearLoading();

    if (success) {
      appStateProvider.showSuccess();
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In successful! Redirecting...'),
          backgroundColor: Color(0xFF4B744F),
          duration: Duration(seconds: 2),
        ),
      );
      
      print('Google Sign-In successful, navigating based on user role');
      
      // Add a small delay to ensure user data is fully loaded
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Direct navigation as fallback if AuthWrapper doesn't trigger
      if (context.mounted) {
        _navigateBasedOnRole(context, authProvider);
      }
    } else {
      // Check if this is a new user who needs to select a role
      if (authProvider.firebaseUser != null && authProvider.currentUser == null) {
        // New user - navigate to role selection
        print('Google Sign-In: New user, navigating to role selection');
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const GoogleRoleSelectionScreen(),
            ),
          );
        }
      } else {
        // Actual error occurred
        print('Google Sign-In failed: ${authProvider.errorMessage}');
        if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty) {
          appStateProvider.showError(authProvider.errorMessage!);
        }
      }
      // Note: User cancellation doesn't show an error
    }
  }

  // Navigate based on user role
  void _navigateBasedOnRole(BuildContext context, AuthProvider authProvider) {
    final userRole = authProvider.currentUser?.role;
    print('Login: Navigating based on role: $userRole');
    
    if (userRole == UserRole.shipper) {
      print('Login: Navigating to Shipper Dashboard');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ShipperDashboardMainPage()),
        (route) => false,
      );
    } else if (userRole == UserRole.carrier) {
      print('Login: Navigating to Carrier Onboarding Wrapper');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CarrierOnboardingWrapper()),
        (route) => false,
      );
    } else {
      print('Login: Role not determined, navigating to AuthWrapper');
      // If role is not determined, navigate to AuthWrapper
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
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
                  // We've removed the 'Center' widget and made the Container fill the entire space
                  // by setting its width and height to double.infinity. This eliminates the white
                  // gaps at the top and bottom caused by the previous fixed height.
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
                            // Leather Image from joiningoption.dart
                            SizedBox(
                              width: double.infinity,
                              height: 250 * scale, // Adjust height as needed
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

                            // Email Field (from XML rectangle_2)
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
                            SizedBox(height: 17 * scale),

                            // Password Field (from XML rectangle_3)
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
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  cursorColor: Colors.black,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      fontSize: 16 * scale,
                                      color: const Color(0x40000000),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey,
                                        size: 24 * scale,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16 * scale,
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 35 * scale),

                            // Remember me and Forgot Password (Fixed overflow)
                            SizedBox(
                              width: 314 * scale,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            rememberMe = !rememberMe;
                                          });
                                        },
                                        child: Container(
                                          width: 20 * scale,
                                          height: 21 * scale,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F8F8),
                                            borderRadius: BorderRadius.circular(5 * scale),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x40000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: rememberMe
                                              ? Icon(
                                            Icons.check,
                                            size: 16 * scale,
                                            color: Colors.black,
                                          )
                                              : null,
                                        ),
                                      ),
                                      SizedBox(width: 8 * scale),
                                      Text(
                                        "Remember me",
                                        style: TextStyle(
                                          fontSize: 11 * scale,
                                          color: const Color(0x61000000),
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      fontSize: 11 * scale,
                                      color: const Color(0x40000000),
                                      ),
                                    ),
                                  ),
                                ],
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

                            // Login Button
                            GestureDetector(
                              onTap: _handleLogin,
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
                                          "Log in",
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
                            SizedBox(height: 10 * scale),

                            // Social login text
                            Text(
                              "or sign in with",
                              style: TextStyle(
                                fontSize: 15 * scale,
                                color: const Color(0x8A000000),
                              ),
                            ),
                            SizedBox(height: 10 * scale),

                            // Social buttons (Google and Apple)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                                  icon: Image.asset('assets/google.png', width: 24 * scale, height: 24 * scale),
                                  label: Text(
                                    "Sign In with Google",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14 * scale,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20 * scale),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 10 * scale),
                                    elevation: 4,
                                  ),
                                ),
                                SizedBox(width: 10 * scale),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: Image.asset('assets/apple.png', width: 24 * scale, height: 24 * scale),
                                  label: Text(
                                    "Sign In with Apple",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14 * scale,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20 * scale),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 10 * scale),
                                    elevation: 4,
                                  ),
                                ),
                              ],
                            ),
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
                        // This will navigate back to the previous screen.
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