import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignScreen(),
    );
  }
}

class SignScreen extends StatelessWidget {
  const SignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6), // rectangle_1 background
      body: Stack(
        children: [
          // leather_roa image
          Positioned(
            left: 0,
            top: -222,
            child: Image.asset(
              'assets/leather.png',
              width: 430,
              height: 443,
              fit: BoxFit.cover,
            ),
          ),

          // rectangle_2 (Sign In button)
          Positioned(
            left: 74,
            top: 525,
            child: Container(
              width: 281,
              height: 49,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                "Sign In",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "HelveticaRounded",
                  color: Color(0xFF113F29),
                ),
              ),
            ),
          ),

          // rectangle_3 (Sign Up button)
          Positioned(
            left: 74,
            top: 598,
            child: Container(
              width: 281,
              height: 49,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "HelveticaRounded",
                  color: Color(0xFF144731),
                ),
              ),
            ),
          ),

          // image_2 (SVG 244x143)
          Positioned(
            left: 96,
            top: 323,
            child: SizedBox(
              width: 244,
              height: 143,
              child: SvgPicture.asset(
                'assets/Option 1.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
