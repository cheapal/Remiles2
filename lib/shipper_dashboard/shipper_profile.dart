import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ShipperProfile(),
  ));
}

class ShipperProfile extends StatefulWidget {
  const ShipperProfile({super.key});

  @override
  State<ShipperProfile> createState() => _ShipperProfileState();
}

class _ShipperProfileState extends State<ShipperProfile>
    with TickerProviderStateMixin {
  int _selectedTab = 3; // Profile tab

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
              // Padding(
              //   padding: EdgeInsets.symmetric(
              //       horizontal: isTabletOrDesktop ? sidePadding : 0.0),
              //   child: Container(
              //     width: double.infinity,
              //     padding:
              //     const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
              //           _buildTopIconWithLabel(Icons.school, 'Academy'),
              //           _buildTopIconWithLabel(Icons.help_outline, 'Support'),
              //           _buildTopIconWithLabel(Icons.message, 'Messages'),
              //           _buildTopIconWithLabel(Icons.notifications, 'Notifications'),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),

              // Main content
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isTabletOrDesktop ? 100.0 : 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Header
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 50),
                            Container(
                              width: 172,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF43975A), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Farm Valley Ltd.',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Color(0xFF186230),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 106,
                          height: 106,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF43975A),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 93.26,
                              height: 93.26,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFFEF6),
                              ),
                              child: const Icon(Icons.person, size: 70, color: Color(0xFF43975A)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Ratings and Shipments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFDD610)),
                        const SizedBox(width: 5),
                        const Text(
                          '4.8 Ratings',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 16,
                          height: 15,
                          decoration: BoxDecoration(
                            color: const Color(0xFF81AB3A),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Verified',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10),
                        _buildShipmentIcon(),
                        const SizedBox(width: 5),
                        const Text(
                          '24 Shipments',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Profile Options
                    _buildProfileOption('Account Details', Icons.account_circle),
                    const SizedBox(height: 16),
                    _buildProfileOption('Payment Method', Icons.credit_card),
                    const SizedBox(height: 16),
                    _buildProfileOption('Load Preferences', Icons.tune),
                    const SizedBox(height: 16),
                    _buildProfileOption('Documents', Icons.description),
                    const SizedBox(height: 16),
                    _buildProfileOption('Boost My Load', Icons.rocket_launch),
                    const SizedBox(height: 16),
                    _buildProfileOption('Settings', Icons.settings),
                    const SizedBox(height: 16),
                    _buildProfileOption('Help & Legal', Icons.help_outline),
                    const SizedBox(height: 16),
                    // Logout button
                    Container(
                      width: 172,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF43975A), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Log Out',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF186230),
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
      ),
      // bottomNavigationBar: Padding(
      //   padding: EdgeInsets.symmetric(
      //       horizontal: isTabletOrDesktop ? sidePadding : 0.0),
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
      //         onTap: (index) {
      //           setState(() {
      //             _selectedTab = index;
      //           });
      //         },
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

  Widget _buildProfileOption(String text, IconData icon) {
    return Container(
      width: double.infinity,
      height: 41,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.29),
        border: Border.all(color: const Color(0xFF43975A), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF186230)),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF186230),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentIcon() {
    return Container(
      width: 17,
      height: 12,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(Icons.local_shipping, size: 17, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
