import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  final Widget nextScreen;

  const WelcomeScreen({super.key, required this.nextScreen});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      body: SafeArea(
        top: false,

        child: Container(
          color: const Color(0xFFFFFEF6),

          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(height: screenHeight * 0.05),

                  // Logo image with responsive sizing
                  Container(
                    width: screenWidth * 0.3,
                    height: screenWidth * 0.3,
                    constraints: const BoxConstraints(
                      minWidth: 100,
                      maxWidth: 150,
                      minHeight: 100,
                      maxHeight: 150,
                    ),
                    child: Image.network(
                      "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/61276312-ff6a-4cb3-82f8-e125853c72cf",
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Welcome text with responsive sizing
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Text(
                      "Welcome\n to Re-Miles",
                      style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: screenWidth * 0.075,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Description text with responsive padding
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      "Your all-in-one freight matching solution that connects carriers and shippers seamlessly optimizing routes, maximizing earnings, and boosting efficiency in the freight industry.",
                      style: TextStyle(
                        color: const Color(0xFF113F29),
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Get Started button with responsive sizing
                  GestureDetector(
                    onTapDown: (details) {
                      setState(() {
                        _scale = 0.95;
                      });
                    },
                    onTapUp: (details) {
                      setState(() {
                        _scale = 1.0;
                      });
                    },
                    onTap: () {
                      print("Get Started tapped!");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => widget.nextScreen),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      transform: Matrix4.identity()..scale(_scale),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.15,
                        vertical: screenHeight * 0.018,
                      ),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        image: DecorationImage(
                          image: NetworkImage("https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/dfac1ec1-15d0-4ecf-bd23-d8d3b1ad2ce6"),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Text(
                        "Get Started",
                        style: TextStyle(
                          color: const Color(0xFFFFFFFF),
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Bottom image with responsive sizing and positioning
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: EdgeInsets.only(left: screenWidth * 0.05),
                      width: screenWidth * 0.6,
                      height: screenHeight * 0.25,
                      child: Image.network(
                        "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/443f2ec2-92ba-466b-b868-e6509a160835",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
