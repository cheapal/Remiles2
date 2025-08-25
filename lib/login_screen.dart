import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool _obscurePassword = true;

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

                      // Username Field (from XML rectangle_2)
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
                          child: TextField(
                            cursorColor: Colors.black, // Changed cursor color to black
                            decoration: InputDecoration(
                              hintText: "Username",
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: 16 * scale,
                                color: const Color(0x40000000), // Faded gray color
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
                          child: TextField(
                            obscureText: _obscurePassword,
                            cursorColor: Colors.black, // Changed cursor color to black
                            decoration: InputDecoration(
                              hintText: "Password",
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: 16 * scale,
                                color: const Color(0x40000000), // Faded gray color
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey, // Faded gray color
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
                            Text(
                              "Forgot Password?",
                              style: TextStyle(
                                fontSize: 11 * scale,
                                color: const Color(0x40000000),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20 * scale),

                      // Login Button
                      GestureDetector(
                        onTap: () {
                          // TODO: Add login functionality
                        },
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
                            child: Text(
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
                            onPressed: () {},
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
  }
}
