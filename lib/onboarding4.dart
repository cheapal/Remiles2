import 'package:flutter/material.dart';

// This is the main entry point of the Flutter application.
void main() {
  runApp(const MyApp());
}

// MyApp is the root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: OnboardingScreen4(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// OnboardingScreen is a stateful widget to manage the state of the checkboxes.
class OnboardingScreen4 extends StatefulWidget {
  const OnboardingScreen4({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen4> {
  // A list to hold the currently selected options.
  final List<String> _selectedOptions = [];

  // A list of all available options for the checkboxes.
  final List<String> _options = [
    "Not enough options",
    "Poor rates",
    "Bad timing",
    "Long wait times",
    "Lack of trust with shippers",
  ];

  // A helper method to build a single animated checkbox option.
  Widget _buildAnimatedCheckboxOption(String optionText) {
    final bool isSelected = _selectedOptions.contains(optionText);
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: 10.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedOptions.remove(optionText);
            } else {
              _selectedOptions.add(optionText);
            }
          });
          print(_selectedOptions);
        },
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: isSelected ? const Color(0xFF537F57) : const Color(0xFFF8F8F8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF537F57).withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  key: ValueKey<bool>(true),
                )
                    : const SizedBox(key: ValueKey<bool>(false)),
              ),
            ),
            const SizedBox(width: 19),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  color: const Color(0xFF38563B),
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFFF5F5F5),
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.02, left: screenWidth * 0.08),
                  child: Text(
                    "Onboarding",
                    style: TextStyle(
                      color: const Color(0xFF537F57),
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.015,
                    left: screenWidth * 0.08,
                    right: screenWidth * 0.08,
                  ),
                  child: Text(
                    "Question 4 of 7: Load Frustration",
                    style: TextStyle(
                      color: const Color(0xFF38563B),
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFFE9E9E9),
                        ),
                      ),
                      Container(
                        width: screenWidth * 0.55,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFF597D5C),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.04,
                    bottom: screenHeight * 0.02,
                    left: screenWidth * 0.08,
                    right: screenWidth * 0.08,
                  ),
                  child: Text(
                    "What's your biggest frustration when trying to find loads?",
                    style: TextStyle(
                      color: const Color(0xFF38563B),
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),

                ..._options.map((option) => _buildAnimatedCheckboxOption(option)),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.03,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: AnimatedTapButton(
                          onTap: () {
                            print('Other button pressed');
                          },
                          child: Container(
                            height: screenHeight * 0.065,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: const Color(0xFFF8F8F8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF6CA78A),
                                  blurRadius: 4,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "Other",
                                style: TextStyle(
                                  color: const Color(0xFF38563B),
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: screenWidth * 0.05),

                      Expanded(
                        flex: 2,
                        child: AnimatedTapButton(
                          onTap: () {
                            print('Next button pressed');
                          },
                          child: Container(
                            height: screenHeight * 0.065,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(37),
                              image: const DecorationImage(
                                image: NetworkImage("https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/cb953b9f-58db-4146-8e32-5c31b85d57d6"),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Next",
                                style: TextStyle(
                                  color: const Color(0xFFFFFFFF),
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  height: screenHeight * 0.25,
                  width: double.infinity,
                  child: Image.network(
                    "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/68073628-f20e-4ac5-817c-b969b60e4fef",
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A reusable widget for creating a tapping animation effect.
class AnimatedTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedTapButton({super.key, required this.child, required this.onTap});

  @override
  AnimatedTapButtonState createState() => AnimatedTapButtonState();
}

class AnimatedTapButtonState extends State<AnimatedTapButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _scale = 0.95);
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
      },
      onTapCancel: () {
        setState(() => _scale = 1.0);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
