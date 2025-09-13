import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShipperDashboardPostLoad extends StatefulWidget {
  const ShipperDashboardPostLoad({super.key});

  @override
  State<ShipperDashboardPostLoad> createState() => _ShipperDashboardPostLoadState();
}

class _ShipperDashboardPostLoadState extends State<ShipperDashboardPostLoad> with TickerProviderStateMixin {
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
    final bool isTabletOrDesktop = MediaQuery.of(context).size.width > 600;
    const sidePadding = 470.0;
    const topPanelColor = Color(0xFF386544);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top section with background image and text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTabletOrDesktop ? sidePadding : 0.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: topPanelColor,
                    image: const DecorationImage(
                      image: AssetImage('assets/top_leather.png'),
                      fit: BoxFit.fill,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/remileswhite.png', height: 60),
                            const Spacer(),
                            _buildTopIconWithLabel(Icons.school, 'Academy'),
                            _buildTopIconWithLabel(Icons.help_outline, 'Support'),
                            _buildTopIconWithLabel(Icons.message, 'Messages'),
                            _buildTopIconWithLabel(Icons.notifications, 'Notifications'),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),

              // Form fields
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTabletOrDesktop ? 100.0 : 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        const Text(
                          'Post a New Load',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 32,
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Image.asset('assets/yellow_trolly.png', width: 30, height: 30),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Origin Address")),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(context, "Destination Address")),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Load Type")),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(context, "Load Sensitivity")),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildTextArea(context, "Please Provide a Specific Load Description"),
                    const SizedBox(height: 25),
                    _buildInputField(context, "Declared Value (For Insurance) (CAD)"),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Pick Up Date/Time")),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(context, "Weight Kg / lbs")),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(context, "Delivery Window")),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInputField(context, "Dimensions (Optional)")),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildInputField(context, "Equipment Needed (Optional)"),
                    const SizedBox(height: 25),
                    _buildInputField(context, "Quote/Budget"),
                    const SizedBox(height: 25),
                    _buildUploadField(
                      context,
                      "Upload Additional Documents (Optional)",
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          "Save As Draft",
                          const Color(0xFF195529),
                          Colors.white,
                              () {},
                          width: 110.45,
                          height: 42.55,
                        ),
                        const SizedBox(width: 15),
                        _buildActionButton(
                          "Post",

                          const Color(0xFFFFCF5F),
                          Colors.black,
                              () {},
                          width: 180,
                          height: 40,
                          isPostLoad: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTabletOrDesktop ? sidePadding : 0.0),
        child: Container(
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFF064232),
            image: DecorationImage(
              image: AssetImage('assets/nav_leather.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.only(
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

  Widget _buildTopIconWithLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 25),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
      BuildContext context,
      String hintText,
      ) {
    return Container(
      width: double.infinity,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(183, 123, 40, 0.44),
            blurRadius: 2.8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: TextField(
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF959595),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea(BuildContext context, String hintText) {
    return Container(
      width: double.infinity,
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(183, 123, 40, 0.44),
            blurRadius: 2.8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: TextField(
          maxLines: null,
          expands: true,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF959595),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadField(BuildContext context, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 57,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(183, 123, 40, 0.44),
                blurRadius: 2.8,
                spreadRadius: 2,
                offset: Offset(0, 2),
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
            fontSize: 13,
            color: Color(0xFF959595),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text,
      Color bgColor,
      Color textColor,
      VoidCallback onPressed, {
        double? width,
        double? height,
        bool isPostLoad = false,
      }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (!isPostLoad)
              const BoxShadow(
                color: Color.fromRGBO(25, 85, 41, 0.36),
                blurRadius: 2.8,
                spreadRadius: 0,
                offset: Offset(0, 2.8),
              ),
            if (isPostLoad)
              const BoxShadow(
                color: Color.fromRGBO(25, 85, 41, 0.36),
                blurRadius: 2.8,
                spreadRadius: 0,
                offset: Offset(0, 2.8),
              ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: isPostLoad ? 20 : 11.2,
              color: textColor,
              fontWeight: isPostLoad ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
