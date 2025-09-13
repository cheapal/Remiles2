import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShipperDashboard3 extends StatefulWidget {
  const ShipperDashboard3({super.key});

  @override
  State<ShipperDashboard3> createState() => _ShipperDashboard3State();
}

class _ShipperDashboard3State extends State<ShipperDashboard3>
    with TickerProviderStateMixin {
  late AnimationController _progressController1;
  int _selectedTab = 0;
  bool _isGstRegistered = false;

  @override
  void initState() {
    super.initState();
    _progressController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _progressController1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;

    // Responsive rules (same approach as your other fixed screen)
    const maxContentWidth = 980.0;
    final horizontalPadding =
    screenW > maxContentWidth ? (screenW - maxContentWidth) / 2 : 16.0;
    final bool isWide = screenW >= 900;

    const topPanelColor = Color(0xFF064232);
    const bottomNavHeight = 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Padding(
            // Center content on large screens; comfy padding on small
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ===== Top section =====
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: topPanelColor,
                    image: isWide
                        ? null
                        : const DecorationImage(
                      image: AssetImage('assets/top_leather.png'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Keep text from overflowing on web
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: const Text(
                              'Please answer the fields below',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 2.0,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9E9E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _progressController1,
                              builder: (context, _) {
                                return Container(
                                  height: 6,
                                  width: 153.0 * _progressController1.value,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCA4D),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== Form fields =====
                Padding(
                  // slightly wider inner padding on desktops
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 100.0 : 40.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        const Text(
                          'Business Number (BN) & GST/HST Registration',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildTextInputField(
                          context: context,
                          hintText: "What is your Business Number (BN)?",
                          subtext:
                          "9-digit CRA-assigned number used for tax purposes.",
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'Are you registered for GST/HST?',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildGstCheckboxes(),
                        const SizedBox(height: 35),
                        const Text(
                          'If your business is not GST/HST registered, you may not be able to reclaim tax credits. Please consult a tax advisor if unsure.',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Add navigation
                            },
                            child: Container(
                              width: 314,
                              height: 57,
                              decoration: BoxDecoration(
                                color: const Color(0xFF195529),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF195529),
                                    blurRadius: 10.5,
                                    spreadRadius: -1,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: const Center(
                                child: Text(
                                  "Submit",
                                  style: TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100), // space above bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ===== Bottom Navigation (responsive padding & texture only on mobile) =====
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          height: bottomNavHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF064232),
            image: isWide
                ? null
                : const DecorationImage(
              image: AssetImage('assets/nav_leather.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(65),
              topRight: Radius.circular(65),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedTab,
              onTap: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFFFFBDF),
              unselectedItemColor: const Color(0xFFFFFBDF).withOpacity(0.6),
              selectedLabelStyle: const TextStyle(fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, size: 26),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart, size: 29),
                  label: 'Manage Loads',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront, size: 30.82),
                  label: 'Marketplace',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person, size: 31.37),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz, size: 25),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Widgets =====

  Widget _buildTextInputField({
    required BuildContext context,
    required String hintText,
    String? subtext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 49,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(108, 167, 138, 0.5),
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: InputBorder.none,
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: Color.fromRGBO(0, 0, 0, 0.45),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (subtext != null)
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 15.0),
            child: Text(
              subtext,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Color.fromRGBO(0, 0, 0, 0.39),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGstCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isGstRegistered = true;
            });
          },
          child: Row(
            children: [
              Container(
                width: 34,
                height: 36,
                decoration: BoxDecoration(
                  color: _isGstRegistered
                      ? const Color(0xFF497A57)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(134, 190, 163, 0.8),
                      blurRadius: 6.6,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _isGstRegistered
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                )
                    : null,
              ),
              const SizedBox(width: 18),
              const Text(
                'Yes',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: () {
            setState(() {
              _isGstRegistered = false;
            });
          },
          child: Row(
            children: [
              Container(
                width: 34,
                height: 36,
                decoration: BoxDecoration(
                  color: !_isGstRegistered
                      ? const Color(0xFF497A57)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(134, 190, 163, 0.8),
                      blurRadius: 6.6,
                    ),
                  ],
                ),
                child: !_isGstRegistered
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                )
                    : null,
              ),
              const SizedBox(width: 18),
              const Text(
                'No',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
