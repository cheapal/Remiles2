import 'package:Remiles/shipper_dashboard/shipper_dashboard_3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShipperDashboard2 extends StatefulWidget {
  const ShipperDashboard2({super.key});

  @override
  State<ShipperDashboard2> createState() => _ShipperDashboard2State();
}

class _ShipperDashboard2State extends State<ShipperDashboard2>
    with TickerProviderStateMixin {
  bool _agreeToTerms = false;
  late AnimationController _progressController1;
  int _selectedTab = 0;

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

    // ======== Responsive rules ========
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
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ======== Top section ========
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
                        // FIX: remove `const` from Center so its non-const children are allowed
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
                              builder: (context, child) {
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

                // ======== Form fields ========
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 100.0 : 40.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        _buildTextInputField(
                          context: context,
                          hintText: "Business Address",
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 25),
                        _buildTextInputField(
                          context: context,
                          hintText: "Operating Province(s)",
                          icon: Icons.flag_outlined,
                        ),
                        const SizedBox(height: 25),
                        _buildTextInputField(
                          context: context,
                          hintText: "Industry Type",
                          icon: Icons.business_center_outlined,
                          subtext: "(manufacturing, retail, agriculture etc.)",
                        ),
                        const SizedBox(height: 25),
                        _buildTextInputField(
                          context: context,
                          hintText: "Frequent shipment type",
                          icon: Icons.local_shipping_outlined,
                          subtext: "(pallets, containers, oversized loads, etc.)",
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'Required Business Documents *',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Color(0xFFFF5454),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Upload clear images (PDF/JPEG/PNG only)',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Color(0xFFA8A8A2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildUploadField(
                          context: context,
                          text:
                          "Business Registration (Articles of Incorporation or Sole Proprietor Certificate)",
                        ),
                        const SizedBox(height: 25),
                        _buildUploadField(
                          context: context,
                          text:
                          "Upload Proof of Business Insurance (Commercial General Liability, Cargo Insurance, etc.)",
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'For safety and compliance, all Re-Miles shippers must provide documentation of valid insurance coverage. This protects your freight and helps us maintain a trusted shipping network.',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF7D8AB0),
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildTextInputField(
                          context: context,
                          hintText: "Insurance provider",
                          icon: Icons.security_outlined,
                        ),
                        const SizedBox(height: 25),
                        _buildTextInputField(
                          context: context,
                          hintText: "Policy Number",
                          icon: Icons.numbers_outlined,
                        ),
                        const SizedBox(height: 25),
                        _buildTextInputField(
                          context: context,
                          hintText: "Expiry Date",
                          icon: Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 25),
                        _buildTextInputField(
                          context: context,
                          hintText: "Coverage Limit",
                          icon: Icons.attach_money_outlined,
                        ),
                        const SizedBox(height: 25),
                        _buildChecklistSection(),
                        const SizedBox(height: 25),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreeToTerms = !_agreeToTerms;
                                });
                              },
                              child: Container(
                                width: 28,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: _agreeToTerms
                                      ? const Color(0xFF4B744F)
                                      : const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.25),
                                      blurRadius: 4,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _agreeToTerms
                                    ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '“I confirm that my business maintains valid insurance coverage and that all uploaded documents are true and accurate.”',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  color: Color(0xFFFF1313),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        _buildUploadField(
                          context: context,
                          text:
                          "Government-Issued ID (for business owner or authorized user)",
                        ),
                        const SizedBox(height: 25),
                        _buildUploadField(
                          context: context,
                          text: "Proof of Address (e.g., Utility bill)",
                        ),
                        const SizedBox(height: 25),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ShipperDashboard3()));
                            },
                            child: Container(
                              width: 110,
                              height: 55,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/signup_button.png'),
                                  fit: BoxFit.fill,
                                ),
                                borderRadius:
                                BorderRadius.all(Radius.circular(24.5)),
                              ),
                              child: const Align(
                                alignment: Alignment(0, -0.2),
                                child: Text(
                                  "Next",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
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

      // ======== Bottom Navigation ========
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

  // ======== Widgets ========

  Widget _buildTextInputField({
    required BuildContext context,
    required String hintText,
    required IconData icon,
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
                Icon(icon, size: 24, color: const Color.fromRGBO(0, 0, 0, 0.45)),
                const SizedBox(width: 10),
                // FIX: TextField is not const; remove const from Expanded/TextField
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
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(0, 0, 0, 0.34),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadField({
    required BuildContext context,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 57,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(25, 85, 41, 0.65),
                blurRadius: 10.5,
                spreadRadius: -1,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/upload_icon.png',
              width: 30,
              height: 30,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.black,
          ),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Accepted formats: PDF, PNG, JPG',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.black,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Minimum requirement: General liability coverage',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.black,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.only(left: 15.0),
          child: Text(
            '• Must name their business\n• Must show general liability or freight-specific coverage',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Colors.black,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
