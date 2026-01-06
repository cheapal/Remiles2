import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Identity colors (same as other Manage Loads screens)
const Color topPanelColor = Color(0xFF386544);
const Color brandGreen = Color(0xFF195529);
const Color aiGradientEnd = Color(0xFF0B7B29);

class ShipperLoadAiMatch extends StatefulWidget {
  const ShipperLoadAiMatch({super.key});

  @override
  State<ShipperLoadAiMatch> createState() => _ShipperLoadAiMatchState();
}

class _ShipperLoadAiMatchState extends State<ShipperLoadAiMatch>
    with TickerProviderStateMixin {
  int _selectedTab = 1; // Manage Loads
  int _statusIndex =
      0; // 0: In-Transit (active), 1: Cancelled Loads, 2: Completed Loads

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;
    const sidePadding = 470.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== Top leather bar (same identity) =====
              TopNavigationBar(context),

              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: isWide ? sidePadding : 0.0),
              //   child: Container(
              //     width: double.infinity,
              //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              //     decoration: BoxDecoration(
              //       color: topPanelColor,
              //       image: const DecorationImage(
              //         image: AssetImage('assets/top_leather.png'),
              //         fit: BoxFit.fill,
              //       ),
              //       boxShadow: [
              //         BoxShadow(
              //           color: Colors.black.withOpacity(0.2),
              //           spreadRadius: 2,
              //           blurRadius: 5,
              //           offset: const Offset(0, 3),
              //         ),
              //       ],
              //       borderRadius: const BorderRadius.only(
              //         bottomLeft: Radius.circular(20),
              //         bottomRight: Radius.circular(20),
              //       ),
              //     ),
              //     child: SafeArea(
              //       child: Row(
              //         children: [
              //           Image.asset('assets/remileswhite.png', height: 60),
              //           const Spacer(),
              //           _topIcon(Icons.school, 'Academy'),
              //           _topIcon(Icons.help_outline, 'Support'),
              //           _topIcon(Icons.message, 'Messages'),
              //           _topIcon(Icons.notifications, 'Notifications'),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),

              // ===== Main content =====
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 100.0 : 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    const Text(
                      'Manage Loads',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search bar (Search My Loads)
                    searchBar(hint: 'Search My Loads'),

                    const SizedBox(height: 18),

                    // Big buttons row: Available Loads | My Bookings
                    Row(
                      children: [
                        bigButton(
                          'Available Loads',
                          bg: Colors.white,
                          textColor: Colors.black,
                        ),
                        const SizedBox(width: 10),
                        bigButton(
                          'My Bookings',
                          bg: Colors.white,
                          textColor: Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status row: In-Transit (active), Cancelled Loads, Completed Loads
                    Row(
                      children: [
                        filterStatusPill('In-Transit', 0, active: true),
                        filterStatusPill('Cancelled Loads', 1),
                        filterStatusPill('Completed Loads', 2),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ===== AI-Matched Load Cards =====
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
                    const SizedBox(height: 16),
                    aiMatchCard(
                      context,
                      recommended: false,
                      matchPercent: 92,
                      loadId: '#1287',
                      from: 'Ottawa, ON',
                      to: 'Quebec City, QC',
                      pickup: 'Sep 2nd, 2025',
                      delivery: 'Sep 4th, 2025',
                      weight: '12,800 lb',
                      docs: '2 Docs',
                      equipment: 'Flatbed',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ===== Bottom navigation (leather) =====
      // bottomNavigationBar: Padding(
      //   padding: EdgeInsets.symmetric(horizontal: isWide ? sidePadding : 0.0),
      //   child: Container(
      //     height: 100,
      //     decoration: const BoxDecoration(
      //       color: Color(0xFF064232),
      //       image: DecorationImage(
      //         image: AssetImage('assets/nav_leather.png'),
      //         fit: BoxFit.cover,
      //       ),
      //       borderRadius: BorderRadius.only(
      //         topLeft: Radius.circular(65),
      //         topRight: Radius.circular(65),
      //       ),
      //     ),
      //     child: ClipRRect(
      //       borderRadius: const BorderRadius.only(
      //         topLeft: Radius.circular(50),
      //         topRight: Radius.circular(50),
      //       ),
      //       child: BottomNavigationBar(
      //         currentIndex: _selectedTab,
      //         onTap: (i) => setState(() => _selectedTab = i),
      //         backgroundColor: Colors.transparent,
      //         elevation: 0,
      //         type: BottomNavigationBarType.fixed,
      //         selectedItemColor: const Color(0xFFFFFBDF),
      //         unselectedItemColor: const Color(0xFFFFFBDF).withOpacity(0.6),
      //         selectedLabelStyle: const TextStyle(fontSize: 11),
      //         unselectedLabelStyle: const TextStyle(fontSize: 11),
      //         items: const [
      //           BottomNavigationBarItem(
      //             icon: Icon(Icons.home, size: 26),
      //             label: 'Home',
      //           ),
      //           BottomNavigationBarItem(
      //             icon: Icon(Icons.shopping_cart, size: 29),
      //             label: 'Manage Loads',
      //           ),
      //           BottomNavigationBarItem(
      //             icon: Icon(Icons.storefront, size: 30.82),
      //             label: 'Marketplace',
      //           ),
      //           BottomNavigationBarItem(
      //             icon: Icon(Icons.person, size: 31.37),
      //             label: 'Profile',
      //           ),
      //           BottomNavigationBarItem(
      //             icon: Icon(Icons.more_horiz, size: 25),
      //             label: 'More',
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
    );
  }

  // ===== Helpers =====

  Widget _topIcon(IconData icon, String label) {
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
}

Widget searchBar({required String hint, bool showTrail = true}) {
  return Container(
    height: 36,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(25, 85, 41, 0.36),
          blurRadius: 2.8,
          spreadRadius: 1,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        const SizedBox(width: 12),
        Icon(Icons.search, size: 18, color: Colors.black.withOpacity(0.6)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF959595),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              isDense: true,
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(width: 6),
        showTrail
            ? Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.tune, size: 18, color: Colors.black),
              )
            : Text(""),
      ],
    ),
  );
}

// Big top buttons
Widget bigButton(String text, {required Color bg, required Color textColor}) {
  return Expanded(
    child: Container(
      height: 32.24,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13.2678),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(25, 85, 41, 0.36),
            blurRadius: 2.0412,
            spreadRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            height: 1.05,
          ),
        ),
      ),
    ),
  );
}

// Small status pills row (for filters)
Widget filterStatusPill(String text, int index, {bool active = false}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        height: 26,
        decoration: BoxDecoration(
          color: active ? brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(13.2678),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(25, 85, 41, 0.36),
              blurRadius: 2.0412,
              spreadRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 9.477,
            ),
          ),
        ),
      ),
    ),
  );
}

// ===== AI Match Load Card =====
Widget aiMatchCard(
  BuildContext context, {
  required bool recommended,
  required int matchPercent,
  required String loadId,
  required String from,
  required String to,
  required String pickup,
  required String delivery,
  required String weight,
  required String docs,
  required String equipment,
  String? status,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(horizontal: 2), // prevent shadow clip
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6CA78A).withOpacity(0.20),
          blurRadius: 13.4,
          spreadRadius: 2,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        // Top row: left details, right status/ID/match score
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///todo: remove recommended - add back later
                  // if (recommended) ...[
                  //   const Text(
                  //     'Recommended Load',
                  //     style: TextStyle(
                  //       fontStyle: FontStyle.italic,
                  //       fontWeight: FontWeight.w700,
                  //       fontSize: 14.3,
                  //       height: 1.05,
                  //       color: Colors.black,
                  //     ),
                  //   ),
                  //   const SizedBox(height: 6),
                  // ],
                  detail(icon: Icons.location_on, text: 'From : $from'),
                  const SizedBox(height: 6),
                  detail(icon: Icons.location_on, text: 'To : $to'),
                  const SizedBox(height: 6),
                  detail(icon: Icons.calendar_today, text: 'Pickup : $pickup'),
                  const SizedBox(height: 6),
                  detail(
                    icon: Icons.calendar_today,
                    text: 'Delivery : $delivery',
                  ),
                ],
              ),
            ),

            // Right: Status gradient pill, ID, match %
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                statusPill(status ?? 'Available'),
                const SizedBox(height: 8),
                Text(
                  'Load ID $loadId',
                  style: const TextStyle(
                    fontSize: 14.4,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                ///todo: enable match in future

                // Text(
                //   '$matchPercent% Match',
                //   style: const TextStyle(
                //     color: Color(0xFF0D7729),
                //     fontWeight: FontWeight.w700,
                //     fontSize: 18.59,
                //     height: 1.05,
                //   ),
                // ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),
        const Divider(height: 20, color: Color(0xFFD9D9D9)),

        // Bottom stats row to reflect design
        Row(
          children: [
            Expanded(
              child: Text(
                weight,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14.3,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  height: 1.05,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Equipment Needed: $equipment',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w600,
                  color: brandGreen,
                  height: 1.05,
                ),
              ),
            ),
            Expanded(
              child: Text(
                docs,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14.3,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget statusPill(String status) {
  // Basic color mapping by status
  Color start = primaryColor;
  Color end = aiGradientEnd;

  final lower = status.toLowerCase();
  if (lower.contains('completed')) {
    start = const Color(0xFF2E7D32); // green
    end = const Color(0xFF66BB6A);
  } else if (lower.contains('in-transit') || lower.contains('in transit')) {
    start = const Color(0xFF1565C0); // blue
    end = const Color(0xFF42A5F5);
  } else if (lower.contains('booked')) {
    start = const Color(0xFFEF6C00); // orange
    end = const Color(0xFFFFA726);
  } else if (lower.contains('cancelled')) {
    start = const Color(0xFFC62828); // red
    end = const Color(0xFFEF5350);
  }

  return Container(
    width: 110.45,
    height: 38.37,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [start, end],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(25, 85, 41, 0.36),
          blurRadius: 2.8,
          spreadRadius: 0,
          offset: Offset(0, 2.8),
        ),
      ],
    ),
    child: Text(
      status,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.05,
      ),
    ),
  );
}

Widget detail({required IconData icon, required String text}) {
  return Row(
    children: [
      Icon(icon, size: 16, color: primaryColor),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            height: 1.05,
          ),
        ),
      ),
    ],
  );
}
