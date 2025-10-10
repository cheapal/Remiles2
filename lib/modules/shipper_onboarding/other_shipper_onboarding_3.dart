import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtherShipperOnboarding3 extends StatelessWidget {
  const OtherShipperOnboarding3({super.key});

  @override
  Widget build(BuildContext context) {
    const double designW = 430.0;
    const double designH = 932.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double scale = (screenWidth / designW < screenHeight / designH)
        ? screenWidth / designW
        : screenHeight / designH;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/other_screen_background.png',
                  fit: BoxFit.cover,
                ),
              ),
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
                    Navigator.of(context).pop();
                  },
                ),
              ),

              Positioned(
                top: 297 * scale,
                left: (designW - 307) / 2 * scale,
                child: Container(
                  width: 307 * scale,
                  height: 213 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20 * scale),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                    child: TextField(
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: "Enter your answer...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          fontSize: 16 * scale,
                          color: const Color(0xFF000000), // Changed color to black
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 620 * scale,
                left: 286 * scale,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 99 * scale,
                    height: 51 * scale,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/signup_button.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(25.5)),
                    ),
                    child: Center(
                      child: Text(
                        "Done",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Color.fromRGBO(0, 0, 0, 0.3),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
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
