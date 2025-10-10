import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for SystemUiOverlayStyle

class CarvonScreen extends StatelessWidget {
  const CarvonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // This makes the status bar icons and text white
      child: Scaffold(
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/carvon_screen_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            // Centered Green Box Image with shadow and padding
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Added padding here
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(20), // Added rounded corners
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20), // Apply to the image itself
                    child: Image.asset(
                      'assets/green_box.png',
                      scale: 1.5, // Made the image slightly smaller
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
