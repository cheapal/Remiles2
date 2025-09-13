import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ===== Brand + Layout constants (reuse across screens if you like) =====
const Color brandColor = Color(0xFF064232); // one source of truth for both bars
const double kMaxContentWidth = 980.0;

class ManageLoadsScreen extends StatefulWidget {
  const ManageLoadsScreen({super.key});

  @override
  State<ManageLoadsScreen> createState() => _ManageLoadsScreenState();
}

class _ManageLoadsScreenState extends State<ManageLoadsScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController1;
  int _selectedTab = 0;
  bool _isSearchActive = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _progressController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _searchCtrl.addListener(() {
      final has = _searchCtrl.text.isNotEmpty;
      if (has != _isSearchActive) {
        setState(() => _isSearchActive = has);
      }
    });
  }

  @override
  void dispose() {
    _progressController1.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ================= Top section =================
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: brandColor, // same color as bottom nav
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

                // ================= Main Content =================
                Padding(
                  // a bit more inner breathing room on desktop
                  padding:
                  EdgeInsets.symmetric(horizontal: isWide ? 100.0 : 20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        const Text(
                          'Manage Loads',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 32,
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildSearchBar(),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            _buildMainButton(
                              '+ Post Loads',
                              const Color(0xFFFFCF5F),
                              Colors.black,
                            ),
                            const SizedBox(width: 15),
                            _buildMainButton(
                              'Booked Loads',
                              const Color(0xFF195529),
                              Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        _buildStatusTabs(),
                        const SizedBox(height: 25),
                        _buildLoadCard(),
                        const SizedBox(height: 20),
                        _buildLoadCard(),
                        const SizedBox(height: 100), // space above bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ================= Bottom Navigation =================
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          height: bottomNavHeight,
          decoration: BoxDecoration(
            color: brandColor, // same color as top bar
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
              onTap: (index) => setState(() => _selectedTab = index),
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

  // ================= Top bar builder =================
  Widget _buildTopBar(bool isWide) {
    if (isWide) {
      // WEB/DESKTOP: inline in a single Row with logo at left and icons at right
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
      // MOBILE/TABLET: wrap looks nicer when narrow
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

  // ================= Widgets =================

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

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(183, 123, 40, 0.44),
            blurRadius: 2.8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(Icons.search, size: 18, color: Colors.black.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search Loads ....',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (_isSearchActive)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                FocusScope.of(context).unfocus();
              },
              child: const Icon(Icons.close, size: 18, color: Colors.black),
            )
          else
            const Icon(Icons.filter_list, size: 18, color: Colors.black),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildMainButton(String text, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(183, 123, 40, 0.44),
              blurRadius: 2.8,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatusButton('Active Loads', const Color(0xFF386544), Colors.white),
          const SizedBox(width: 10),
          _buildStatusButton('In-Transit', const Color(0xFF386544), Colors.white),
          const SizedBox(width: 10),
          _buildStatusButton('Cancelled Loads', Colors.white, Colors.black),
          const SizedBox(width: 10),
          _buildStatusButton('Completed Loads', Colors.white, Colors.black),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF386544)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 13.4,
            spreadRadius: 0,
            offset: Offset(0, 13.4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF386544), size: 18),
                        SizedBox(width: 5),
                        Text(
                          'From : Toronto, ON',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF386544), size: 18),
                        SizedBox(width: 5),
                        Text(
                          'To : Montreal, QC',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF386544),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Color(0xFF386544), size: 16),
                        SizedBox(width: 5),
                        Text(
                          'Pickup : Sep 1st, 2025',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Color(0xFF386544), size: 16),
                        SizedBox(width: 5),
                        Text(
                          'Delivery : Sep 3rd, 2025',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      '#1234',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Equipment Needed: Flatbed',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9.8,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF195529),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bottom stats row – Wrap so it breaks nicely on tight widths
            Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildCardTextWithIcon(
                    Icons.monitor_weight_outlined, '15,000 lb'),
                _buildCardTextWithIcon(
                    Icons.monetization_on_outlined, '\$ 2000'),
                _buildCardTextWithIcon(Icons.route_outlined, '215 (mi)'),
                _buildCardTextWithIcon(Icons.description_outlined, '2 Docs'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTextWithIcon(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF195529)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14.3,
              fontWeight: FontWeight.w600,
              color: Color(0xFF195529),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
