import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Miley UI',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F9F9), // Off-white background
        fontFamily: 'Roboto', // A clean, modern font
      ),
      home: const AiMileyScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AiMileyScreen extends StatelessWidget {
  const AiMileyScreen({super.key});

  // Define the primary color for reuse
  static const Color primaryGreen = Color(0xFF1E4620);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back,
            color: primaryGreen,
            size: 28,
          ),
        ),
        title: const Text(
          'AI Miley',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AI Avatar Icon
                    AiAvatar(),
                    SizedBox(height: 24),
                    // Greeting Text
                    Text(
                      'Good Afternoon\nLascell',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Message Input Field
            const MessageInputField(),
            const SizedBox(height: 20), // Padding from bottom
          ],
        ),
      ),
    );
  }
}

class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = AiMileyScreen.primaryGreen;
    // A slightly lighter green for the outer circle
    final Color lightGreen = HSLColor.fromColor(primaryGreen).withLightness(0.25).toColor();

    return CircleAvatar(
      radius: 70,
      backgroundColor: lightGreen,
      child: CircleAvatar(
        radius: 60,
        backgroundColor: primaryGreen,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.headset_mic,
              color: Colors.white.withOpacity(0.8),
              size: 70,
            ),
            const Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageInputField extends StatelessWidget {
  const MessageInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Text field
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Message',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Voice icon button
        const CircleAvatar(
          radius: 25,
          backgroundColor: AiMileyScreen.primaryGreen,
          child: Icon(
            Icons.graphic_eq_rounded, // This icon resembles sound waves
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}