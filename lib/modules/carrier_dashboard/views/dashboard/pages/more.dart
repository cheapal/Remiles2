import 'package:flutter/foundation.dart';
import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class More extends StatelessWidget {
  const More({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final bool isWide = screenW >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            TopNavigationBar(context),

            const SizedBox(height: 20),

            // Main content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 100.0 : 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: const Text(
                        'More',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: kIsWeb ? 100 : 20),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: _buildOptionCard(
                              title: 'Analytics & Performance',
                              icon: 'assets/performance_analytics.svg',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildOptionCard(
                              title: 'CO₂ Carbon Footprint Tracking',
                              icon: 'assets/eco.svg',
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildOptionCard(
                            title: 'Analytics & Performance',
                            icon: 'assets/performance_analytics.svg',
                          ),
                          const SizedBox(height: 20),
                          _buildOptionCard(
                            title: 'CO₂ Carbon Footprint Tracking',
                            icon: 'assets/eco.svg',
                          ),
                        ],
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildOptionCard({required String title, required String icon}) {
  return Container(
    height: 184,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6CA78A).withOpacity(0.4),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 7),
        ),
        BoxShadow(
          color: primaryColor.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(icon, height: 80, width: 80),
        const SizedBox(height: 15),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}
