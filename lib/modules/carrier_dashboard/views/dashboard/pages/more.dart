import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class More extends StatelessWidget {
  const More({super.key});

  @override
  Widget build(BuildContext context) {
    return  SingleChildScrollView(
      child: Column(
        children: [
        TopNavigationBar(context),

          // Main content
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: //isTabletOrDesktop ? 100.0 :
                20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'More',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // Analytics Card
                _buildOptionCard(
                  title: 'Analytics & Performance',
                  icon: 'assets/performance_analytics.svg',
                ),
                const SizedBox(height: 20),

                // Carbon Footprint Card
                _buildOptionCard(
                  title: 'CO₂ Carbon Footprint Tracking',
                  icon: 'assets/eco.svg',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
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


Widget _buildOptionCard({required String title, required String icon}) {
  return Container(
    width: 347,
    height: 184,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6CA78A).withOpacity(0.4),
          blurRadius: 2,
          spreadRadius: -2,
          offset: const Offset(3, 3),
        ),
        BoxShadow(
          color: primaryColor,
          spreadRadius: 2,
          blurRadius: 2,
          offset: const Offset(-3, -3), // changes position of shadow
        ),

      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
       SvgPicture.asset(icon, height: 80, width: 80,),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}
