import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../models/user_model.dart';
import '../../../core/firebase_service.dart';
import '../../carrier_onboarding/carrier_onboarding_wrapper.dart';
import '../../shipper_onboarding/shipper_onboarding_wrapper.dart';
import '../../shipper_dashboard/pages/shipper_dashboard_4_main_page.dart';
import '../../shipper_dashboard/pages/shipper_dashboard_1.dart';
import '../../carrier_dashboard/views/dashboard/pages/carrier_dashboard_1.dart';
import '../../carrier_dashboard/views/dashboard/pages/main_page.dart';

/// Role selection screen specifically for Google Sign-In flow
/// User is already authenticated via Google, we just need to create their account in Firestore
class GoogleRoleSelectionScreen extends StatelessWidget {
  const GoogleRoleSelectionScreen({super.key});

  // Figma baseline (from your Android XML)
  static const double _designW = 376.0;
  static const double _designH = 936.0;

  // Helpers to scale Figma dp → logical px
  double sx(double val, double scale) => val * scale;
  double sy(double val, double scale) => val * scale;

  Future<void> _handleRoleSelection(BuildContext context, String role) async {
    HapticFeedback.selectionClick();
    
    final authProvider = context.read<AuthProvider>();
    final appStateProvider = context.read<AppStateProvider>();
    
    // Get Firebase user directly from Firebase Auth if not available in AuthProvider
    // This handles cases where AuthProvider state might have been cleared
    var firebaseUser = authProvider.firebaseUser;
    if (firebaseUser == null) {
      // Fallback: Get directly from Firebase
      firebaseUser = FirebaseService.currentUser;
      if (firebaseUser != null) {
        // Update AuthProvider with the Firebase user
        authProvider.setUserData(firebaseUser, null);
      }
    }

    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please try signing in again.')),
      );
      return;
    }

    try {
      appStateProvider.showLoadingWithMessage('Setting up your account...');

      // Get user info from Google
      final email = firebaseUser.email ?? '';
      final displayName = firebaseUser.displayName ?? email.split('@')[0];
      final photoUrl = firebaseUser.photoURL;

      bool success = false;
      if (role == 'Carrier') {
        success = await authProvider.createCarrierFromGoogle(
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        );
      } else if (role == 'Shipper') {
        success = await authProvider.createShipperFromGoogle(
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        );
      }

      if (success) {
        appStateProvider.showSuccess();
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (context.mounted) {
          await _navigateBasedOnRole(context, authProvider);
        }
      } else {
        final errorMsg = authProvider.errorMessage ?? 'Failed to create account';
        debugPrint('Error creating account: $errorMsg');
        appStateProvider.showError(errorMsg);
        // Show detailed error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in role selection: $e');
      debugPrint('Stack trace: $stackTrace');
      final errorMsg = 'An error occurred: ${e.toString()}';
      appStateProvider.showError(errorMsg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _navigateBasedOnRole(BuildContext context, AuthProvider authProvider) async {
    final userRole = authProvider.currentUser?.role;
    print('Google Role Selection: Navigating based on role: $userRole');
    
    if (userRole == UserRole.shipper) {
      final shipper = authProvider.shipperUser;
      if (shipper != null && !shipper.isOnboardingComplete) {
        print('Google Role Selection: Navigating to Shipper Onboarding');
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ShipperOnboardingWrapper()),
            (route) => false,
          );
        }
      } else if (shipper != null) {
        // Check if dashboard steps are completed
        print('Google Role Selection: Checking if dashboard steps are completed...');
        final isDashboardComplete = await FirebaseService.isShipperDashboardComplete(shipper.uid);
        print('Google Role Selection: Dashboard complete: $isDashboardComplete');
        
        if (!isDashboardComplete) {
          print('Google Role Selection: Navigating to Shipper Dashboard 1');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ShipperDashboard1()),
              (route) => false,
            );
          }
        } else {
          print('Google Role Selection: Navigating to Shipper Dashboard Main Page');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ShipperDashboardMainPage()),
              (route) => false,
            );
          }
        }
      }
    } else if (userRole == UserRole.carrier) {
      final carrier = authProvider.carrierUser;
      if (carrier != null && !carrier.isOnboardingComplete) {
      print('Google Role Selection: Navigating to Carrier Onboarding Wrapper');
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CarrierOnboardingWrapper()),
          (route) => false,
        );
        }
      } else if (carrier != null) {
        // Check if dashboard steps are completed
        print('Google Role Selection: Checking if carrier dashboard steps are completed...');
        final isDashboardComplete = await FirebaseService.isCarrierDashboardComplete(carrier.uid);
        print('Google Role Selection: Carrier dashboard complete: $isDashboardComplete');
        
        if (!isDashboardComplete) {
          print('Google Role Selection: Navigating to Carrier Dashboard 1');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CarrierDashboard1()),
              (route) => false,
            );
          }
        } else {
          print('Google Role Selection: Navigating to Carrier Main Page');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainPage()),
              (route) => false,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double w = size.width;
    final double h = size.height;

    // Maintain Figma proportions: use the smaller scale so nothing overflows
    final double scale = (w / _designW < h / _designH) ? (w / _designW) : (h / _designH);

    // Panel (rectangle_6) — Figma width is 376dp, full height
    final double panelW = sx(_designW * 1.12, scale);
    final double panelH = h;
    final double panelLeft = (w - panelW) / 2.0;

    // Cards (rectangle_8 & rectangle_9): 314×304 at Y=529dp and Y=199dp
    const double cardDW = 284.0;
    const double cardDH = 304.0;
    final double cardW = sx(cardDW, scale);
    final double cardH = sy(cardDH, scale);
    final double cardX = panelLeft + sx((_designW - cardDW) / 2.0, scale);
    final double card1Top = sy(199.0, scale);
    final double card2Top = sy(529.0, scale);

    // Title at marginTop=120dp, centered
    final double titleTop = sy(120.0, scale);

    // Image box inside cards
    final double imgBox = sx(235.0, scale);
    final double imgTopPadding = sy(18.0, scale);

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              // Background leather texture
              Positioned.fill(
                child: Image.asset(
                  'assets/leather_rectangle.png',
                  fit: BoxFit.cover,
                ),
              ),

              // White panel
              Positioned(
                left: panelLeft,
                top: 0,
                width: panelW,
                height: panelH,
                child: Image.asset(
                  'assets/white_rectangle.png',
                  fit: BoxFit.fill,
                ),
              ),

              // Title centered at ~120dp from the top
              Positioned(
                top: titleTop,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Choose your role',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: sx(29, scale),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 38 / 32,
                    ),
                  ),
                ),
              ),

              // Top card (Carrier)
              Positioned(
                left: cardX,
                top: card1Top,
                width: cardW + 40,
                height: cardH,
                child: _RoleCard(
                  title: 'Carrier',
                  imageUrl: 'assets/carrier_icon.png',
                  scale: scale,
                  imgSize: imgBox,
                  imgTop: imgTopPadding + sy(15.0, scale),
                  onTap: () => _handleRoleSelection(context, 'Carrier'),
                ),
              ),

              // Bottom card (Shipper)
              Positioned(
                left: cardX,
                top: card2Top,
                width: cardW + 40,
                height: cardH,
                child: _RoleCard(
                  title: 'Shipper',
                  imageUrl: 'assets/shipper_icon.png',
                  scale: scale,
                  imgSize: imgBox,
                  imgTop: imgTopPadding + sy(-15.0, scale),
                  onTap: () => _handleRoleSelection(context, 'Shipper'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.imageUrl,
    required this.scale,
    required this.imgSize,
    required this.imgTop,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final double scale;
  final double imgSize;
  final double imgTop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius cardRadius = BorderRadius.circular(33 * scale);

    return _PressableScale(
      scaleAmount: 0.97,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      borderRadius: cardRadius,
      enableInkRipple: true,
      onTap: onTap,
      child: Material(
        elevation: 4,
        color: Colors.white,
        borderRadius: cardRadius,
        shadowColor: Colors.green.withOpacity(0.95),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: cardRadius,
          ),
          child: Stack(
            children: [
              // Image
              Positioned(
                top: imgTop,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: imgSize,
                    height: imgSize,
                    child: _PressableScale(
                      scaleAmount: 0.95,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                      onTap: onTap,
                      child: Image.asset(
                        imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              // Title
              Positioned(
                left: 0,
                right: 0,
                bottom: title == 'Shipper' ? 15 * scale : 25 * scale,
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 23 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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
}

/// A tiny helper that gives a tactile press animation (scale down then up).
class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.child,
    required this.onTap,
    this.scaleAmount = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOut,
    this.borderRadius,
    this.enableInkRipple = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scaleAmount;
  final Duration duration;
  final Curve curve;
  final BorderRadius? borderRadius;
  final bool enableInkRipple;

  @override
  State<_PressableScale> createState() => __PressableScaleState();
}

class __PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final scaled = _pressed ? widget.scaleAmount : 1.0;

    final content = AnimatedScale(
      scale: scaled,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );

    if (widget.enableInkRipple) {
      return Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          child: content,
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}

