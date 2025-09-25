import 'package:Remiles/shipper_dashboard/shipper_dashboard_2.dart';
import 'package:Remiles/shipper_dashboard/shipper_dashboard_post_load.dart';
import 'package:Remiles/shipper_dashboard/shipper_load_ai_match.dart';
import 'package:Remiles/shipper_dashboard/widgets/load_card.dart';
import 'package:Remiles/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'business_form_screen.dart';


// Define the dark color for the side navigation and bottom bar.
const Color webColor = Color(0xFF064232);
const Color darkGreen = Color(0xFF386544);
const Color yellow = Color(0xFFFFCA4D);
const Color offWhite = Color(0xFFFFF6E1);

class ShipperDashboard_4_main_page extends StatefulWidget {
  const ShipperDashboard_4_main_page({super.key});
  @override
  State<ShipperDashboard_4_main_page> createState() => _ShipperDashboard_4_main_pageState();
}

class _ShipperDashboard_4_main_pageState extends State<ShipperDashboard_4_main_page>
    with TickerProviderStateMixin {
  late AnimationController _progressController1;
  late AnimationController _progressController2;
  // A key to control the Scaffold's drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTab = 0;
  double _xPosition = 0;
  double _yPosition = 0;
  @override
  void initState() {
    super.initState();
    _progressController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() => setState(() {}))
      ..forward();
    _progressController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() => setState(() {}))
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      const iconWidth = 72.0;
      const iconHeight = 72.0;
      const bottomNavHeight = 100.0;
      const padding = 20.0;
      setState(() {
        _xPosition = screenWidth - iconWidth - padding;
        _yPosition = screenHeight - bottomNavHeight - iconHeight - padding;
      });
    });
  }

  @override
  void dispose() {
    _progressController1.dispose();
    _progressController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final screenH = media.size.height;
    // Layout constants
    const topSectionHeight = 110.0;
    const bottomNavHeight = 100.0;
    const iconHeight = 72.0;
    const dragPadding = 20.0;
    // Responsive container
    const maxContentWidth = 980.0;
    final horizontalPadding = screenW > maxContentWidth
        ? (screenW - maxContentWidth) / 2
        : 16.0;
    final bool isWide = screenW >= 900;
    // Drag bounds
    final double maxIconY = screenH - bottomNavHeight - iconHeight;
    final double minIconY = topSectionHeight;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey, // Assign the key to the Scaffold
        // Use a conditional AppBar for mobile and a persistent sidebar for web
        drawer: isWide ? const SideNavDrawer() : null,
        // Add a conditional AppBar

        extendBodyBehindAppBar: true,
        body: Row(
          children: [
            // Conditionally show the SideNavDrawer on wide screens
            if (isWide) const SideNavDrawer(),
            Expanded(
              child: Stack(
                children: [
                  // Main content body
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top section with progress bar
                        // ================= Top section =================
                        /// Top Navigation Bar
                        TopNavigationBar(context),
                        SizedBox(height: isWide ? 50.0 : 16.0),
                        // Main content
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding + 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome + avatar
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Welcome\nJohn Doe',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 71,
                                    height: 71,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: darkGreen,
                                          width: 2),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      'assets/profile_icon.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // CTA buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        //show dialog
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return  ShipperDashboardPostLoad();
                                          },
                                        );
                                      },
                                      child: Container(
                                        height: 49,
                                        decoration: BoxDecoration(
                                          color: yellow,
                                          borderRadius: BorderRadius.circular(26),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                              Colors.black.withOpacity(0.66),
                                              spreadRadius: -1,
                                              blurRadius: 3.5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add, color: Colors.black),
                                              SizedBox(width: 6),
                                              Text(
                                                'Post new load',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Container(
                                      height: 51,
                                      decoration: BoxDecoration(
                                        color: darkGreen,
                                        borderRadius: BorderRadius.circular(26),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                            Colors.black.withOpacity(0.66),
                                            spreadRadius: -1,
                                            blurRadius: 3.5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '\$',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'Payment',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Loads Summary
                              const Text(
                                'Loads Summary',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.36),
                                      spreadRadius: 0,
                                      blurRadius: 2.8,
                                      offset: const Offset(0, 2.8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Tabs
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                setState(() => _selectedTab = 0),
                                            child: Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 8),
                                              decoration: BoxDecoration(
                                                color: _selectedTab == 0
                                                    ? darkGreen
                                                    : Colors.white,
                                                borderRadius:
                                                BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.36),
                                                    spreadRadius: 0,
                                                    blurRadius: 2.8,
                                                    offset:
                                                    const Offset(0, 2.8),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'All Loads',
                                                  style: TextStyle(
                                                    color: _selectedTab == 0
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                setState(() => _selectedTab = 1),
                                            child: Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 8),
                                              decoration: BoxDecoration(
                                                color: _selectedTab == 1
                                                    ? darkGreen
                                                    : Colors.white,
                                                borderRadius:
                                                BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.36),
                                                    spreadRadius: 0,
                                                    blurRadius: 2.8,
                                                    offset:
                                                    const Offset(0, 2.8),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'In Progress',
                                                  style: TextStyle(
                                                    color: _selectedTab == 1
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                setState(() => _selectedTab = 2),
                                            child: Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 8),
                                              decoration: BoxDecoration(
                                                color: _selectedTab == 2
                                                    ? darkGreen
                                                    : Colors.white,
                                                borderRadius:
                                                BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.36),
                                                    spreadRadius: 0,
                                                    blurRadius: 2.8,
                                                    offset:
                                                    const Offset(0, 2.8),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Completed',
                                                  style: TextStyle(
                                                    color: _selectedTab == 2
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    aiMatchCard(
                                      context,
                                      recommended: true,
                                      matchPercent: 97,
                                      loadId: '#1234',
                                      from: 'Toronto, ON',
                                      to: 'Montreal. QC',
                                      pickup: 'Sep 1st, 2025',
                                      delivery: 'Sep 3rd, 2025',
                                      weight: '15,000 lb',
                                      docs: '2 Docs',
                                      equipment: 'Flatbed',
                                    ),

                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Stat cards row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(26)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6CA78A)
                                                .withOpacity(0.5),
                                            spreadRadius: 0,
                                            blurRadius: 10,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 46,
                                                height: 46,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFFBFF497),
                                                ),
                                                child: const Center(
                                                  child: Image(
                                                    image: AssetImage(
                                                        'assets/green_trolly.png'),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    '42',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight
                                                          .w500, // Updated font weight
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Total Loads Posted',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight
                                                  .w600, // Updated font weight
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(26)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6CA78A)
                                                .withOpacity(0.5),
                                            spreadRadius: 0,
                                            blurRadius: 10,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 46,
                                                height: 46,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: offWhite,
                                                ),
                                                child: const Center(
                                                  child: Image(
                                                    image: AssetImage(
                                                        'assets/orange_tick.png'),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    '95%',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight
                                                          .w500, // Updated font weight
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Loads Delivered on time',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight
                                                  .w600, // Updated font weight
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Carrier Match Rate
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFFFFF),
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(26)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                      Color.fromRGBO(0, 128, 0, 0.36),
                                      spreadRadius: 0,
                                      blurRadius: 2.8,
                                      offset: Offset(0, 2.8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        const Image(
                                          image: AssetImage(
                                              'assets/yellow_truck.png'),
                                          width: 46,
                                          height: 46,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: SizedBox(
                                            height: 6.0,
                                            child: ClipRRect(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                              child: LinearProgressIndicator(
                                                value: 0.87,
                                                backgroundColor:
                                                Colors.grey[300],
                                                valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                                    Color(0xFFEE9D6F)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          '87%',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Carrier Match Rate',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  height: 120), // spacing above bottom nav
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Floating movable icon
                  Positioned(
                    left: _xPosition,
                    top: _yPosition,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _xPosition = (_xPosition + details.delta.dx)
                              .clamp(0, screenW - 72);
                          _yPosition = (_yPosition + details.delta.dy)
                              .clamp(minIconY, maxIconY);
                        });
                      },
                      onPanEnd: (_) {
                        const iconWidth = 72.0;
                        setState(() {
                          if (_xPosition < screenW / 2 - iconWidth / 2) {
                            _xPosition = dragPadding;
                          } else {
                            _xPosition = screenW - iconWidth - dragPadding;
                          }
                        });
                      },
                      child: const Image(
                        image: AssetImage('assets/miley_icon.png'),
                        width: 72,
                        height: 72,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            height: bottomNavHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/nav_leather.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedTab,
                onTap: (index) => setState(() => _selectedTab = index),
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: offWhite,
                unselectedItemColor:
                offWhite.withOpacity(0.6),
                selectedLabelStyle: const TextStyle(fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                items: const [
                  BottomNavigationBarItem(
                    icon: ImageIcon(AssetImage('assets/home_icon.png'),
                        size: 26),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(AssetImage('assets/trolly_icon.png'),
                        size: 29),
                    label: 'Manage Loads',
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(AssetImage('assets/marketplace.png'),
                        size: 30.82),
                    label: 'Marketplace',
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(AssetImage('assets/user_icon.png'),
                        size: 31.37),
                    label: 'Profile',
                  ),
                  BottomNavigationBarItem(
                    icon: ImageIcon(AssetImage('assets/more_icon.png'),
                        size: 25),
                    label: 'More',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // ================= Top bar builder =================
  Widget _buildTopBar(bool isWide) {
    if (isWide) {
      // WEB/DESKTOP: inline in a single Row with logo at left and icons at right
      return Row(
        children: [
          Image.asset('assets/remileswhite.png', height: 60),
          const Spacer(),
          _buildTopIconWithLabel(Icons.school, 'Academy'),
          const SizedBox(width: 16),
          _buildTopIconWithLabel(Icons.help_outline, 'Support'),
          const SizedBox(width: 16),
          _buildTopIconWithLabel(Icons.message, 'Messages'),
          const SizedBox(width: 16),
          _buildTopIconWithLabel(Icons.notifications, 'Notifications'),
        ],
      );
    } else {
      // MOBILE/TABLET: wrap looks nicer when narrow
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Image.asset('assets/remileswhite.png', height: 60),
          _buildTopIconWithLabel(Icons.school, 'Academy'),
          _buildTopIconWithLabel(Icons.help_outline, 'Support'),
          _buildTopIconWithLabel(Icons.message, 'Messages'),
          _buildTopIconWithLabel(Icons.notifications, 'Notifications'),
        ],
      );
    }
  }

  // ================= Widgets =================

  Widget _buildTopIconWithLabel(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
    );
  }

}

/// A stateful Drawer widget with a custom header for the Re-Miles app.
/// It features a white background, black text, and highlights the selected
/// and hovered item with a green background and white text.
class SideNavDrawer extends StatefulWidget {
  const SideNavDrawer({super.key});

  @override
  State<SideNavDrawer> createState() => _SideNavDrawerState();
}

class _SideNavDrawerState extends State<SideNavDrawer> {
  int _selectedIndex = 0; // Tracks the selected item index

  // Color constants for easy modification
  static const Color selectedColor = Color(0xFF386544); // Green for selection
  static const Color defaultColor = Colors.black87; // Black for text/icons
  static const Color hoverColor =
  Color(0xFFE8F5E9); // Light green for hover

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // The overall background of the drawer is white
      backgroundColor: Colors.white,
      elevation: 1, // A subtle shadow to distinguish from the main content
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Custom Drawer Header
          Container(
            padding: const EdgeInsets.only(
                top: 50.0, left: 20.0, right: 20.0, bottom: 20.0),
            child: Row(
              children: [
                // ### UPDATED LOGO ###
                const CircleAvatar(
                  backgroundColor: Colors.transparent, // Avoid color clash
                  backgroundImage: AssetImage('assets/remiles.png'),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [

                      // // ### UPDATED APP NAME ###
                      // Text(
                      //   'Re-Miles',
                      //   style: TextStyle(
                      //     color: Colors.black,
                      //     fontSize: 18,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Menu Section
          _buildSectionHeader('Menus'),
          _buildDrawerItem(
              icon: Icons.dashboard, text: 'Dashboard', index: 0),
          _buildDrawerItem(icon: Icons.task_alt, text: 'My Task', index: 1),
          _buildDrawerItem(
              icon: Icons.calendar_today, text: 'Calendar', index: 2),
          _buildDrawerItem(icon: Icons.mail_outline, text: 'Mail', index: 3),
          _buildDrawerItem(icon: Icons.history, text: 'Activity', index: 4),
          const Divider(
              height: 20, thickness: 1, indent: 20, endIndent: 20),
          // Service Section
          _buildSectionHeader('Service'),
          _buildDrawerItem(
              icon: Icons.analytics_outlined, text: 'SEO', index: 5),
          _buildDrawerItem(
              icon: Icons.web_outlined, text: 'Web Design', index: 6),
          _buildDrawerItem(
              icon: Icons.design_services_outlined,
              text: 'Logo Design',
              index: 7),
          // This pushes the footer to the bottom
          const SizedBox(height: 50),
          // Footer Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create new task',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF386544),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }





  // Helper widget for drawer list items
  Widget _buildDrawerItem(
      {required IconData icon, required String text, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: ListTile(
        selected: isSelected,
        // The background color when the item is selected.
        selectedTileColor: selectedColor,
        // The color when the user hovers over the item.
        hoverColor: selectedColor.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        leading: Icon(
          icon,
          // Icon color is white if selected, otherwise black.
          color: isSelected ? Colors.white : defaultColor,
        ),
        title: Text(
          text,
          style: TextStyle(
            // Text color is white if selected, otherwise black.
            color: isSelected ? Colors.white : defaultColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          // Add any navigation logic here, e.g., Navigator.pop(context);
        },
        dense: true,
      ),
    );
  }
}