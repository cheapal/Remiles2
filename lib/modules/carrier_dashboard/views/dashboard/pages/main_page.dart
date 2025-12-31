import 'package:remiles/modules/carrier_dashboard/views/common/widgets/bottom_navigation_bar.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/profile.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_market_place_Screen.dart';
import 'package:remiles/modules/shipper_dashboard/pages/ai_miley_page.dart';
import 'package:flutter/material.dart';

import 'carrier_dashboard.dart';
import 'manage_load.dart';
import 'more.dart';

// Define the green color for AI Miley button
const Color green = Color(0xFF497A57);

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;
  bool _isOnAiMileyPage = false;

  final _tabKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // void _onTap(int newIndex) {
  //   if (newIndex == _index) {
  //     // if re-tapping the same tab, pop to first route
  //     _tabKeys[newIndex].currentState?.popUntil((r) => r.isFirst);
  //   } else {
  //     setState(() => _index = newIndex);
  //   }
  // }

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
        body: Stack(
          children: [
            IndexedStack(
              index: _index,
              children: [
                _buildTabNavigator(_tabKeys[0],  CarrierDashboardScreen()),
                _buildTabNavigator(_tabKeys[1], const ManageLoadScreen()),
                _buildTabNavigator(_tabKeys[2], const ShipperMarketplaceScreen()),
                _buildTabNavigator(_tabKeys[3],  Profile()),
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
                    final currentNavigator = _tabKeys[_index].currentState;
                    if (currentNavigator != null) {
                      setState(() {
                        _isOnAiMileyPage = true; // Hide button when navigating to AI Miley
                      });
                      Navigator.push(
                        currentNavigator.context,
                        MaterialPageRoute(
                          builder: (context) => const AiMileyScreen(),
                        ),
                      ).then((_) {
                        // Show button again when returning from AI Miley page
                        setState(() {
                          _isOnAiMileyPage = false;
                        });
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
                        )
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
        bottomNavigationBar: BottomNavigationBarTab(
          currentIndex: _index,
          onTap: _onTap,
        ),
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
