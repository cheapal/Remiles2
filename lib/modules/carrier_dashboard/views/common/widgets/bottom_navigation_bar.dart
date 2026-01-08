import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BottomNavigationBarTab extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavigationBarTab({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0A6837),
        image: DecorationImage(
          image: AssetImage('assets/leather_square.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset("assets/home.svg", width: 24, height: 24),
            label: "Home",
            tooltip: "Home",
            
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              "assets/manage_load.svg",
              width: 24,
              height: 24,
            ),
            label: "Manage Loads",
            tooltip: "Manage Loads",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              "assets/marketplace_bottom_nav.svg",
              width: 24,
              height: 24,
            ),
            label: "Marketplace",
            tooltip: "Marketplace",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              "assets/person_bottom_nav.svg",
              width: 24,
              height: 24,
            ),
            label: "Profile",
            tooltip: "Profile",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              "assets/menu_bottom_nav.svg",
              color: Colors.white,
              width: 24,
              height: 24,
            ),
            label: "More",
            tooltip: "More",
          ),
        ],
      ),
    );
  }
}
