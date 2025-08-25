import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'carrier_signup.dart'; // Assuming the file path for CarrierSignUpScreen
import 'joiningoption.dart';
import 'shipper_signup.dart'; // Import the new ShipperSignUpScreen

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  // Figma baseline (from your Android XML)
  static const double _designW = 376.0;
  static const double _designH = 936.0;

  // Helpers to scale Figma dp → logical px
  double sx(double val, double scale) => val * scale;
  double sy(double val, double scale) => val * scale;

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
    final Size size = MediaQuery.of(context).size;
    final double w = size.width;
    final double h = size.height;

    // Maintain Figma proportions: use the smaller scale so nothing overflows
    final double scale = (w / _designW < h / _designH) ? (w / _designW) : (h / _designH);

    // Panel (rectangle_6) — Figma width is 376dp, full height
    // Increased width for the white rectangle
    final double panelW = sx(_designW * 1.12, scale);
    final double panelH = h; // span full device height

    // Horizontally center the panel like layout_centerHorizontal="true"
    final double panelLeft = (w - panelW) / 2.0;

    // Cards (rectangle_8 & rectangle_9): 314×304 at Y=529dp and Y=199dp
    const double cardDW = 284.0;
    const double cardDH = 304.0;
    final double cardW = sx(cardDW, scale);
    final double cardH = sy(cardDH, scale);
    final double cardX = panelLeft + sx((_designW - cardDW) / 2.0, scale); // centered in the 376 panel
    final double card1Top = sy(199.0, scale); // top card
    final double card2Top = sy(529.0, scale); // bottom card

    // Title at marginTop=120dp, centered
    final double titleTop = sy(120.0, scale);

    // Back button placement (about 57dp from top, a bit in from left)
    final double backTop = sy(57.0, scale);
    final double backLeft = panelLeft + sx(16.0, scale);

    // Image box inside cards
    final double imgBox = sx(235.0, scale);
    final double imgTopPadding = sy(18.0, scale);

    void onBackTap() {
      HapticFeedback.selectionClick();
      Navigator.maybePop(context);
    }

    void onRoleTap(String role) {
      HapticFeedback.selectionClick();
      // Navigate to the CarrierSignUpScreen when the "Carrier" role is tapped.
      if (role == 'Carrier') {
        Navigator.of(context).push(
          _createFadePageRoute(const CarrierSignUpScreen()),
        );
      } else if (role == 'Shipper') {
        Navigator.of(context).push(
          _createFadePageRoute(const ShipperSignUpScreen()),
        );
      }
      debugPrint('Tapped role: $role');
    }

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark, // This makes status bar icons black
        child: SafeArea(
          top: false, // flush to the very top (no white gap)
          bottom: false, // flush to the very bottom (no white gap)
          child: Stack(
            children: [
              // Background leather texture — full bleed
              Positioned.fill(
                child: Image.asset(
                  'assets/leather_rectangle.png',
                  fit: BoxFit.cover,
                ),
              ),

              // White panel (rectangle_6) centered horizontally
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

              // Back button with press animation
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
                      _createFadePageRoute(const SignScreen(nextScreen: Text("Login Screen Placeholder"))),
                    );
                  },
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
                      height: 38 / 32, // line height mapping
                    ),
                  ),
                ),
              ),

              // Top card (Carrier)
              Positioned(
                left: cardX,

                top: card1Top,
                width: cardW+40,
                height: cardH,
                child: _RoleCard(
                  title: 'Carrier',
                  imageUrl: 'assets/carrier_icon.png',
                  scale: scale,
                  imgSize: imgBox,
                  imgTop: imgTopPadding + sy(15.0, scale), // Pushed down for spacing
                  onTap: () => onRoleTap('Carrier'),
                ),
              ),

              // Bottom card (Shipper)
              Positioned(
                left: cardX,
                top: card2Top,
                width: cardW+40,
                height: cardH,
                child: _RoleCard(
                  title: 'Shipper',
                  imageUrl: 'assets/shipper_icon.png',
                  scale: scale,
                  imgSize: imgBox,
                  imgTop: imgTopPadding + sy(-15.0, scale), // Pushed down for spacing
                  onTap: () => onRoleTap('Shipper'),
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
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
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
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
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

    // Optional material ripple
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

    // Gesture-based (no ripple)
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

    return PressableScale(
      scaleAmount: 0.97,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      borderRadius: cardRadius,
      enableInkRipple: true,
      onTap: onTap,
      child: Material(
        elevation: 4, // <-- matches your XML android:elevation="4dp"
        color: Colors.white,
        borderRadius: cardRadius,
        shadowColor: Colors.green.withOpacity(0.95), // subtle Material shadow
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
                    child: PressableScale(
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
