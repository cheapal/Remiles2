import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/bottom_navigation_bar.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/profile.dart';
import 'package:flutter/material.dart';

import 'carrier_dashboard.dart';
import 'manage_load.dart';
import 'marketplace_screen.dart';
import 'more.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

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
    setState(() => _index = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // handle Android back button
      onWillPop: () async {
        final currentNavigator = _tabKeys[_index].currentState!;
        if (currentNavigator.canPop()) {
          currentNavigator.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            _buildTabNavigator(_tabKeys[0],  CarrierDashboardScreen()),
            _buildTabNavigator(_tabKeys[1], const ManageLoadScreen()),
            _buildTabNavigator(_tabKeys[2], const MarketplaceScreen()),
            _buildTabNavigator(_tabKeys[3],  Profile()),
            _buildTabNavigator(_tabKeys[4], More()),
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
