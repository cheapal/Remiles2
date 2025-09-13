import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ===== Brand + layout constants =====
const Color brandColor = Color(0xFF064232); // one source of truth for both bars
const double kMaxContentWidth = 980.0;

class ManageLoads2 extends StatefulWidget {
  const ManageLoads2({super.key});

  @override
  State<ManageLoads2> createState() => _ManageLoads2State();
}

class _ManageLoads2State extends State<ManageLoads2>
    with TickerProviderStateMixin {
  int _selectedTab = 1; // Start on 'Manage Loads' tab

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final bool isWide = screenW >= 900;
    final double horizontalPadding =
    screenW > kMaxContentWidth ? (screenW - kMaxContentWidth) / 2 : 16.0;

    const double bottomNavHeight = 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Padding(
            // Center content on desktop, comfy padding on mobile/tablet
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                // ===== Top section (shared brand color, leather only on narrow) =====
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: brandColor,
                    image: isWide
                        ? null
                        : const DecorationImage(
                      image: AssetImage('assets/top_leather.png'),
                      fit: BoxFit.cover,
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
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(isWide),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // ===== Main content =====
                Padding(
                  // a bit more inner breathing room on desktop
                  padding:
                  EdgeInsets.symmetric(horizontal: isWide ? 100.0 : 20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 20),

                        // Search bar
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color:
                                const Color(0xFFB77B28).withOpacity(0.44),
                                blurRadius: 2.8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 10),
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText:
                                      'Search trucks, trailers, parts ....',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF959595),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.only(right: 10.0),
                                child: Icon(
                                  Icons.tune,
                                  color: Colors.black.withOpacity(0.6),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Post and Booked Loads buttons
                        Row(
                          children: [
                            _buildPrimaryButton(
                                '+ Post Loads',
                                const Color(0xFFFFCF5F),
                                Colors.black),
                            const SizedBox(width: 10),
                            _buildPrimaryButton(
                                'Booked Loads', Colors.white, Colors.black),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Active Loads and In-Transit buttons (4 columns, Expanded keeps them even)
                        Row(
                          children: [
                            _buildLoadsButton(
                                'Active Loads', false, context),
                            _buildLoadsButton(
                                'In-Transit', true, context),
                            _buildLoadsButton(
                                'Cancelled Loads', false, context),
                            _buildLoadsButton(
                                'Completed Loads', false, context),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Load Cards
                        _buildLoadCard(context, 'In-Transit'),
                        const SizedBox(height: 20),
                        _buildLoadCard(context, 'Available'),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ===== Bottom Navigation (same brand color as top) =====
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          height: bottomNavHeight,
          decoration: BoxDecoration(
            color: brandColor,
            image: isWide
                ? null
                : const DecorationImage(
              image: AssetImage('assets/nav_leather.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: const BorderRadius.only(
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
              unselectedItemColor:
              const Color(0xFFFFFBDF).withOpacity(0.6),
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

  // ===== Top bar: inline on web, wrapped on narrow =====
  Widget _buildTopBar(bool isWide) {
    if (isWide) {
      // WEB/DESKTOP: inline in a single Row with logo left and icons right
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
      // MOBILE/TABLET: Wrap so it looks nice when narrow
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

  // ===== Buttons & controls =====

  Widget _buildPrimaryButton(String text, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB77B28).withOpacity(0.44),
              blurRadius: 2.8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadsButton(
      String text, bool isActive, BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          height: 26,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF195529) : Colors.white,
            borderRadius: BorderRadius.circular(13.2678),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF195529).withOpacity(0.36),
                spreadRadius: 1,
                blurRadius: 2.0412,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 9.477,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===== Card =====

  Widget _buildLoadCard(BuildContext context, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CA78A).withOpacity(0.2),
            blurRadius: 13.4,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: origin/destination + status chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                      icon: Icons.location_on,
                      text: 'From : Toronto, ON'),
                  const SizedBox(height: 5),
                  _buildDetailRow(
                      icon: Icons.location_on,
                      text: 'To : Montreal. QC'),
                  const SizedBox(height: 5),
                  _buildDetailRow(
                      icon: Icons.calendar_today,
                      text: 'Pickup : Sep 1st, 2025'),
                  const SizedBox(height: 5),
                  _buildDetailRow(
                      icon: Icons.calendar_today,
                      text: 'Delivery : Sep 3rd, 2025'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (status == 'In-Transit')
                    Container(
                      width: 99.41,
                      height: 31.5,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4078A2), Color(0xFF1D3487)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF195529).withOpacity(0.36),
                            blurRadius: 2.52,
                            spreadRadius: 0,
                            offset: const Offset(0, 2.52),
                          ),
                        ],
                      ),
                      child: const Text(
                        'In-Transit',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.7,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (status == 'Available')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF386544),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Available',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 5),
                  if (status == 'In-Transit')
                    Container(
                      width: 99,
                      height: 22.05,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3482BD),
                        borderRadius: BorderRadius.circular(6.3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF195529).withOpacity(0.36),
                            blurRadius: 1.764,
                            spreadRadius: 0,
                            offset: const Offset(0, 1.764),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Track',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.19,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    '#1234',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Equipment Needed: Flatbed',
                    style: TextStyle(
                        color: Color(0xFF195529),
                        fontSize: 9.8,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFD9D9D9)),

          // Bottom stats row — Wrap so it breaks nicely on tight widths
          Wrap(
            spacing: 16,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildLoadStatsItem(
                  text: '15,000 lb', textColor: const Color(0xFF195529)),
              _buildLoadStatsItem(
                  text: '\$ 2000', textColor: const Color(0xFFCEB838)),
              _buildLoadStatsItem(
                  text: '215 (mi)', textColor: const Color(0xFF195529)),
              _buildLoadStatsItem(
                  text: '2 Docs', textColor: const Color(0xFF195529)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF195529)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF195529),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadStatsItem(
      {required String text, required Color textColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.3,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
