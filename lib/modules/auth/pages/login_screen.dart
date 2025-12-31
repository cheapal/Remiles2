import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../core/auth_wrapper.dart';
import '../../../core/firebase_service.dart';
import '../../../models/user_model.dart';
import '../../shipper_dashboard/pages/shipper_dashboard_4_main_page.dart';
import '../../shipper_dashboard/pages/shipper_dashboard_1.dart';
import '../../carrier_onboarding/carrier_onboarding_wrapper.dart';
import '../../shipper_onboarding/shipper_onboarding_wrapper.dart';
import '../../carrier_dashboard/views/dashboard/pages/carrier_dashboard_1.dart';
import '../../carrier_dashboard/views/dashboard/pages/main_page.dart';
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
  
  // Track validation errors to display them without layout shift
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Load remembered email after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRememberedEmail();
    });
  }

  // Load remembered email on screen initialization
  Future<void> _loadRememberedEmail() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final rememberedEmail = await authProvider.getRememberedEmail();
    if (rememberedEmail != null && rememberedEmail.isNotEmpty && mounted) {
      setState(() {
        _emailController.text = rememberedEmail;
        rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle login
  Future<void> _handleLogin() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    
    if (!_formKey.currentState!.validate()) {
      // Update error states after validation
      setState(() {
        if (_emailController.text.isEmpty) {
          _emailError = 'Please enter your email';
        } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
          _emailError = 'Please enter a valid email';
        }
        
        if (_passwordController.text.isEmpty) {
          _passwordError = 'Please enter your password';
        } else if (_passwordController.text.length < 6) {
          _passwordError = 'Password must be at least 6 characters';
        }
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final appStateProvider = context.read<AppStateProvider>();

    appStateProvider.showLoadingWithMessage('Signing in...');

    final success = await authProvider.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      // Save email if "Remember me" is checked
      if (rememberMe) {
        await authProvider.saveRememberedEmail(_emailController.text.trim());
      } else {
        // Clear saved email if "Remember me" is unchecked
        await authProvider.clearRememberedEmail();
      }

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
        await _navigateBasedOnRole(context, authProvider);
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
        await _navigateBasedOnRole(context, authProvider);
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
  Future<void> _navigateBasedOnRole(BuildContext context, AuthProvider authProvider) async {
    final userRole = authProvider.currentUser?.role;
    print('Login: Navigating based on role: $userRole');
    
    if (userRole == UserRole.shipper) {
      final shipper = authProvider.shipperUser;
      if (shipper != null && shipper.isOnboardingComplete == false) {
        print('Login: Navigating to Shipper Onboarding');
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ShipperOnboardingWrapper()),
            (route) => false,
          );
        }
      } else if (shipper != null) {
        // Check if dashboard steps are completed
        print('Login: Checking if dashboard steps are completed...');
        final isDashboardComplete = await FirebaseService.isShipperDashboardComplete(shipper.uid);
        print('Login: Dashboard complete: $isDashboardComplete');
        
        if (!isDashboardComplete) {
          print('Login: Navigating to Shipper Dashboard 1');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ShipperDashboard1()),
              (route) => false,
            );
          }
        } else {
          print('Login: Navigating to Shipper Dashboard Main Page');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ShipperDashboardMainPage()),
              (route) => false,
            );
          }
        }
      } else {
        print('Login: No shipper data, navigating to AuthWrapper');
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
    } else if (userRole == UserRole.carrier) {
      final carrier = authProvider.carrierUser;
      if (carrier != null && carrier.isOnboardingComplete == false) {
      print('Login: Navigating to Carrier Onboarding Wrapper');
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CarrierOnboardingWrapper()),
          (route) => false,
        );
        }
      } else if (carrier != null) {
        // Check if dashboard steps are completed
        print('Login: Checking if carrier dashboard steps are completed...');
        final isDashboardComplete = await FirebaseService.isCarrierDashboardComplete(carrier.uid);
        print('Login: Carrier dashboard complete: $isDashboardComplete');
        
        if (!isDashboardComplete) {
          print('Login: Navigating to Carrier Dashboard 1');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CarrierDashboard1()),
              (route) => false,
            );
          }
        } else {
          print('Login: Navigating to Carrier Main Page');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainPage()),
              (route) => false,
            );
          }
        }
      } else {
        print('Login: No carrier data, navigating to AuthWrapper');
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
    } else {
      print('Login: Role not determined, navigating to AuthWrapper');
      // If role is not determined, navigate to AuthWrapper
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
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
                            if (!kIsWeb) ...[
                           SizedBox(
                              width: double.infinity,
                              height: 250 * scale, // Adjust height as needed
                              child: Image.asset(
                                'assets/leather.png',
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                            ],
                          if(kIsWeb) ...[
                            SizedBox(height: 200),
                            ],
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        String? error;
                                        if (value == null || value.isEmpty) {
                                          error = 'Please enter your email';
                                        } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          error = 'Please enter a valid email';
                                        }
                                        // Update error state
                                        if (mounted) {
                                          setState(() {
                                            _emailError = error;
                                          });
                                        }
                                        return error;
                                      },
                                      onChanged: (value) {
                                        // Clear error when user starts typing
                                        if (_emailError != null && mounted) {
                                          setState(() {
                                            _emailError = null;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Email Address",
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          fontSize: 16 * scale,
                                          color: const Color(0x40000000),
                                        ),
                                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                                      ),
                                      style: TextStyle(
                                        fontSize: 16 * scale,
                                        color: const Color(0xFF000000),
                                      ),
                                    ),
                                  ),
                                ),
                                // Error message space for email (reserved to prevent layout shift)
                                SizedBox(
                                  width: 314 * scale,
                                  height: 20 * scale,
                                  child: _emailError != null
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                            left: (456 - 314) / 2 * scale + 24.5 * scale,
                                            top: 4 * scale,
                                          ),
                                          child: Text(
                                            _emailError!,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 12 * scale,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            SizedBox(height: 17 * scale),

                            // Password Field (from XML rectangle_3)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        String? error;
                                        if (value == null || value.isEmpty) {
                                          error = 'Please enter your password';
                                        } else if (value.length < 6) {
                                          error = 'Password must be at least 6 characters';
                                        }
                                        // Update error state
                                        if (mounted) {
                                          setState(() {
                                            _passwordError = error;
                                          });
                                        }
                                        return error;
                                      },
                                      onChanged: (value) {
                                        // Clear error when user starts typing
                                        if (_passwordError != null && mounted) {
                                          setState(() {
                                            _passwordError = null;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Password",
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          fontSize: 16 * scale,
                                          color: const Color(0x40000000),
                                        ),
                                        errorStyle: const TextStyle(height: 0, fontSize: 0),
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
                                // Error message space for password (reserved to prevent layout shift)
                                SizedBox(
                                  width: 314 * scale,
                                  height: 20 * scale,
                                  child: _passwordError != null
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                            left: (456 - 314) / 2 * scale + 24.5 * scale,
                                            top: 4 * scale,
                                          ),
                                          child: Text(
                                            _passwordError!,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 12 * scale,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
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
                                        onTap: () async {
                                          setState(() {
                                            rememberMe = !rememberMe;
                                          });
                                          // If unchecked, clear saved email
                                          if (!rememberMe) {
                                            final authProvider = context.read<AuthProvider>();
                                            await authProvider.clearRememberedEmail();
                                          }
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