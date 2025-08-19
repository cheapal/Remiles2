import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    Timer(
      const Duration(seconds: 3),
          () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: SizedBox(
              width: screenWidth * 0.6,
              height: screenWidth * 0.4,
              child: Image.asset(
                "assets/remiles.png",
                fit: BoxFit.contain,
                frameBuilder: (BuildContext context,
                    Widget child,
                    int? frame,
                    bool wasSynchronouslyLoaded,) {
                  if (wasSynchronouslyLoaded) return child;
                  if (frame == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: child,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                      Icons.broken_image, size: 100, color: Colors.grey);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
