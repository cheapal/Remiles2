
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/academy.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/messages_page.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/notification.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


Widget TopNavigationBar(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      color: Color(0xFF0A6837), // dark green background
      image: DecorationImage(
        image: AssetImage('assets/nav_leather.png'),
        fit: BoxFit.cover,
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(1),
        topRight: Radius.circular(1),
      ),
    ),
    child: SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SvgPicture.asset('assets/remiles.svg'),
          Row(
            children: [
              _navItem(
                context,
                icon: SvgPicture.asset("assets/academy_top_nav.svg", width: 24, height: 24),
                label: "Academy",
                page: const AcademyScreen(), // placeholder
              ),
              const SizedBox(width: 10),
              _navItem(
                context,
                icon: SvgPicture.asset("assets/support_top_nav.svg", width: 24, height: 24),
                label: "Support",
                page: SupportScreen(),
              ),
              const SizedBox(width: 10),
              _navItem(
                context,
                icon:SvgPicture.asset("assets/messages_top_nav.svg", width: 24, height: 24),
                label: "Messages",
                page: const MessagesPage(),
              ),
              const SizedBox(width: 10),
              _navItem(
                context,
                icon: SvgPicture.asset("assets/notification_top_nav.svg", width: 24, height: 24),
                label: "Notifications",
                page: const NoNotificationPage(),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _navItem(BuildContext context,
    {required SvgPicture icon, required String label, required Widget page}) {
  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    },
    borderRadius: BorderRadius.circular(8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
