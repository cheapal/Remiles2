import 'package:remiles/modules/carrier_dashboard/views/common/widgets/bottom_navigation_bar.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/profile.dart';
import 'package:remiles/modules/shipper_dashboard/pages/market_place_Screen.dart';
import 'package:remiles/modules/shipper_dashboard/pages/ai_miley_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'carrier_dashboard_home_page.dart';
import 'manage_load.dart';
import 'more.dart';

// Reuse the background color from shipper if available, or define it here
const Color backgroundColor = Color(0xFFFFFEF6);

class CarrierWebSideBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CarrierWebSideBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color selectedColor = Color(0xFF386544);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: const Border(
          right: BorderSide(color: Color(0xFF386544), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header / Logo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Image.asset('assets/remiles.png', height: 60),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(0, 'assets/home.svg', 'Home', selectedColor),
                _buildNavItem(
                  1,
                  'assets/manage_load.svg',
                  'Manage Loads',
                  selectedColor,
                ),
                _buildNavItem(
                  2,
                  'assets/marketplace_bottom_nav.svg',
                  'Marketplace',
                  selectedColor,
                ),
                _buildNavItem(
                  3,
                  'assets/person_bottom_nav.svg',
                  'Profile',
                  selectedColor,
                ),
                _buildNavItem(
                  4,
                  'assets/menu_bottom_nav.svg',
                  'More',
                  selectedColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String iconPath,
    String label,
    Color selectedColor,
  ) {
    final bool isSelected = currentIndex == index;
    // Styling constants
    final Color textColor = isSelected ? Colors.white : Colors.black87;
    final Color iconColor = isSelected ? Colors.white : Colors.black54;
    final Color tileColor = isSelected ? selectedColor : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  color: iconColor,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

// Define the green color for AI Miley button
const Color green = Color(0xFF497A57);

class CarrierDashboardMainPage extends StatefulWidget {
  const CarrierDashboardMainPage({super.key});

  @override
  State<CarrierDashboardMainPage> createState() =>
      _CarrierDashboardMainPageState();
}

class _CarrierDashboardMainPageState extends State<CarrierDashboardMainPage> {
  int _index = 0;
  bool _isOnAiMileyPage = false;

  final _tabKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onTap(int newIndex) {
    // Always pop the navigator of the destination tab to its first route.
    _tabKeys[newIndex].currentState?.popUntil((r) => r.isFirst);
    // Update the index to switch the tab.
    setState(() {
      _index = newIndex;
      _isOnAiMileyPage = false; // Reset when switching tabs
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;

    // Use a breakpoint for "wide" screens (e.g. tablet landscape / desktop)
    final bool isWide = screenW >= 900;

    return WillPopScope(
      // handle Android back button
      onWillPop: () async {
        final currentNavigator = _tabKeys[_index].currentState!;
        if (currentNavigator.canPop()) {
          currentNavigator.pop();
          setState(() {
            _isOnAiMileyPage = false; // Reset when popping
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Container(
          color: backgroundColor,
          child: Row(
            children: [
              // Side Bar for Web/Wide screens
              if (isWide)
                CarrierWebSideBar(currentIndex: _index, onTap: _onTap),

              // Main Content Area
              Expanded(
                child: Stack(
                  children: [
                    IndexedStack(
                      index: _index,
                      children: [
                        _buildTabNavigator(
                          _tabKeys[0],
                          CarrierDashboardHomeScreen(),
                        ),
                        _buildTabNavigator(
                          _tabKeys[1],
                          const ManageLoadScreen(),
                        ),
                        _buildTabNavigator(
                          _tabKeys[2],
                          const MarketplaceScreen(),
                        ),
                        _buildTabNavigator(_tabKeys[3], Profile()),
                        _buildTabNavigator(_tabKeys[4], More()),
                      ],
                    ),
                    // AI Miley floating button - only show when not on AI Miley page
                    if (!_isOnAiMileyPage)
                      Positioned(
                        bottom: 35, // Position above the bottom navigation bar
                        right: 20,
                        child: GestureDetector(
                          onTap: () {
                            final currentNavigator =
                                _tabKeys[_index].currentState;
                            if (currentNavigator != null) {
                              setState(() {
                                _isOnAiMileyPage =
                                    true; // Hide button when navigating to AI Miley
                              });
                              Navigator.push(
                                currentNavigator.context,
                                MaterialPageRoute(
                                  builder: (context) => const AiMileyScreen(),
                                ),
                              ).then((_) {
                                // Show button again when returning from AI Miley page
                                if (mounted) {
                                  setState(() {
                                    _isOnAiMileyPage = false;
                                  });
                                }
                              });
                            }
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: green.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Image(
                              image: AssetImage('assets/miley_icon.png'),
                              width: 72,
                              height: 72,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: !isWide
            ? BottomNavigationBarTab(currentIndex: _index, onTap: _onTap)
            : null,
      ),
    );
  }

  Widget _buildTabNavigator(GlobalKey<NavigatorState> key, Widget child) {
    return Navigator(
      key: key,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => child);
      },
    );
  }
}
