import 'package:flutter/material.dart';

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
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1024;

    final fieldMargin = isDesktop ? 80.0 : isTablet ? 60.0 : 40.0;

    return Scaffold(
      body: SafeArea(
        top: false, // ✅ allow content to start at the very top (no white gap)
        bottom: false, // ✅ allow content to end at the very bottom (no white gap)
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF5F5F5),
                          width: double.infinity,
                          height: double.infinity,
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ---------- Logo & Banner (no top margin) ----------
                                  Container(
                                    margin: EdgeInsets.only(
                                      bottom: isTablet ? 60 : 41,
                                      // top: isTablet ? 40 : 20, // ❌ removed to kill the top white gap
                                    ),
                                    width: double.infinity,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(
                                                bottom: isTablet ? 120 : 100,
                                              ),
                                              width: double.infinity,
                                              height: isDesktop ? 300 : isTablet ? 280 : 250,
                                              child: Image.network(
                                                "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/cf7da3e8-f48f-4e5f-beeb-b66f438bc75f",
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: screenHeight * (isTablet ? 0.25 : 0.33),
                                          left: 0,
                                          right: 0,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final screenW = constraints.maxWidth;
                                              final double logoW = isDesktop
                                                  ? 200.0
                                                  : isTablet
                                                  ? 160.0
                                                  : (screenW * 0.3).clamp(100.0, 180.0).toDouble();

                                              return Center(
                                                child: SizedBox(
                                                  width: logoW,
                                                  child: Image.network(
                                                    "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/671a2d5b-b5b4-45ae-916e-4ba86e321c9d",
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ---------- Username Field ----------
                                  Container(
                                    margin: EdgeInsets.only(
                                      left: fieldMargin,
                                      right: fieldMargin,
                                      bottom: 10,
                                      top: 17,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(33),
                                      color: const Color(0xFFFFFFFF),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x40000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: "Username",
                                        hintStyle: TextStyle(
                                          color: const Color(0x40000000),
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 31,
                                          vertical: isTablet ? 20 : 16,
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: const Color(0xFF000000),
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // ---------- Password Field with Eye Icon ----------
                                  Container(
                                    margin: EdgeInsets.only(
                                      left: fieldMargin,
                                      right: fieldMargin,
                                      bottom: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(33),
                                      color: const Color(0xFFFFFFFF),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x40000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        hintText: "Password",
                                        hintStyle: TextStyle(
                                          color: const Color(0x40000000),
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 31,
                                          vertical: isTablet ? 20 : 16,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.grey,
                                            size: isTablet ? 28 : 24,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: const Color(0xFF000000),
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // ---------- Remember me row ----------
                                  Container(
                                    margin: EdgeInsets.only(
                                      bottom: 33,
                                      left: fieldMargin + 11,
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              rememberMe = !rememberMe;
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(5),
                                              color: Colors.white,
                                            ),
                                            margin: const EdgeInsets.only(right: 14),
                                            width: isTablet ? 24 : 20,
                                            height: isTablet ? 25 : 21,
                                            child: rememberMe
                                                ? Icon(
                                              Icons.check,
                                              size: isTablet ? 20 : 16,
                                              color: Colors.green,
                                            )
                                                : null,
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Remember me",
                                                style: TextStyle(
                                                  color: const Color(0x40000000),
                                                  fontSize: isTablet ? 14 : 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "Forgot Password?",
                                                style: TextStyle(
                                                  color: const Color(0x40000000),
                                                  fontSize: isTablet ? 14 : 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ---------- Login Button ----------
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isDesktop ? 120 : isTablet ? 80 : 60,
                                      vertical: 8,
                                    ),
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(37)),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/19ef2f6e-72f5-4b86-a0ab-dfc05762b872",
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isTablet ? 16 : 10,
                                        ),
                                        child: Text(
                                          "Log in",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: const Color(0xFFFFFFFF),
                                            fontSize: isTablet ? 20 : 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ---------- Sign up prompt ----------
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: TextStyle(
                                            color: const Color(0x40000000),
                                            fontSize: isTablet ? 16 : 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Add signup navigation
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                          ),
                                          child: Text(
                                            "Sign up",
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ---------- Divider ----------
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 17),
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    child: Container(
                                      color: Colors.black.withOpacity(0.25),
                                      width: isTablet ? 250 : 188,
                                      height: 1,
                                    ),
                                  ),

                                  // ---------- Social login text ----------
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 19),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "or sign in with",
                                      style: TextStyle(
                                        color: const Color(0x40000000),
                                        fontSize: isTablet ? 18 : 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // ---------- Social buttons ----------
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () {},
                                        child: Image.network(
                                          "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/d180c7bd-c886-4b5f-bad3-4dcbd82f252b",
                                          width: isTablet ? 40 : 30,
                                          height: isTablet ? 40 : 30,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 32 : 24),
                                      InkWell(
                                        onTap: () {},
                                        child: Image.network(
                                          "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/be2d3860-8734-426f-8795-05ddfd5970d3",
                                          width: isTablet ? 50 : 40,
                                          height: isTablet ? 50 : 40,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isTablet ? 40 : 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
