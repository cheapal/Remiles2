import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManageLoads3 extends StatefulWidget {
  const ManageLoads3({super.key});

  @override
  State<ManageLoads3> createState() => _ManageLoads3State();
}

class _ManageLoads3State extends State<ManageLoads3> with TickerProviderStateMixin {
  int _selectedTab = 1; // Start on 'Manage Loads' tab

  @override
  Widget build(BuildContext context) {
    final bool isTabletOrDesktop = MediaQuery.of(context).size.width > 600;
    const sidePadding = 470.0;
    const topPanelColor = Color(0xFF386544);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top section with background image and icons (unified)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTabletOrDesktop ? sidePadding : 0.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: topPanelColor,
                    image: const DecorationImage(
                      image: AssetImage('assets/top_leather.png'),
                      fit: BoxFit.fill,
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
                    child: Row(
                      children: [
                        Image.asset('assets/remileswhite.png', height: 60),
                        const Spacer(),
                        _buildTopIconWithLabel(Icons.school, 'Academy'),
                        _buildTopIconWithLabel(Icons.help_outline, 'Support'),
                        _buildTopIconWithLabel(Icons.message, 'Messages'),
                        _buildTopIconWithLabel(Icons.notifications, 'Notifications'),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isTabletOrDesktop ? 100.0 : 20.0),
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
                            color: const Color(0xFFB77B28).withOpacity(0.44),
                            blurRadius: 2.8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search trucks, trailers, parts ....',
                                  hintStyle: TextStyle(color: Color(0xFF959595), fontSize: 13, fontWeight: FontWeight.w600),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Icon(Icons.tune, color: Colors.black.withOpacity(0.6), size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Post and Booked Loads buttons
                    Row(
                      children: [
                        _buildPrimaryButton('+ Post Loads', const Color(0xFFFFCF5F), Colors.black),
                        const SizedBox(width: 10),
                        _buildPrimaryButton('Booked Loads', const Color(0xFF195529), Colors.white),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status buttons
                    Row(
                      children: [
                        _buildLoadsButton('Active Loads', false, context),
                        _buildLoadsButton('In-Transit', false, context),
                        _buildLoadsButton('Cancelled Loads', false, context),
                        _buildLoadsButton('Completed Loads', false, context),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Load Card
                    _buildLoadCard(context, 'Booked'),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTabletOrDesktop ? sidePadding : 0.0),
        child: Container(
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFF064232),
            image: DecorationImage(
              image: AssetImage('assets/nav_leather.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.only(
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
              unselectedItemColor: const Color(0xFFFFFBDF).withOpacity(0.6),
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

  // Unified top bar helper (same as other screens)
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

  // ==== Existing helpers ====

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
          child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLoadsButton(String text, bool isActive, BuildContext context) {
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
    );
  }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(icon: Icons.location_on, text: 'From : Toronto, ON'),
                  const SizedBox(height: 5),
                  _buildDetailRow(icon: Icons.location_on, text: 'To : Montreal. QC'),
                  const SizedBox(height: 5),
                  _buildDetailRow(icon: Icons.calendar_today, text: 'Pickup : Sep 1st, 2025'),
                  const SizedBox(height: 5),
                  _buildDetailRow(icon: Icons.calendar_today, text: 'Delivery : Sep 3rd, 2025'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (status == 'Booked')
                    Container(
                      width: 99.41,
                      height: 31.5,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF99A2D),
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
                        'Booked',
                        style: TextStyle(color: Colors.white, fontSize: 11.7, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (status == 'Available')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF386544),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Available',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    '#1234',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Equipment Needed: Flatbed',
                    style: TextStyle(color: Color(0xFF195529), fontSize: 9.8, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFD9D9D9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLoadStatsItem(text: '15,000 lb', textColor: const Color(0xFF195529)),
              _buildLoadStatsItem(text: '\$ 2000', textColor: const Color(0xFFCEB838)),
              _buildLoadStatsItem(text: '215 (mi)', textColor: const Color(0xFF195529)),
              _buildLoadStatsItem(text: '2 Docs', textColor: const Color(0xFF195529)),
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
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF195529))),
      ],
    );
  }

  Widget _buildLoadStatsItem({required String text, required Color textColor}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.3,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
