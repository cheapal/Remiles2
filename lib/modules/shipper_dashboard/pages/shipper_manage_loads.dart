import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/filter_manage_loads.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_booked_loads.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_dashboard_post_load.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';


// ===== Brand + Layout constants (reuse across screens if you like) =====
const Color brandColor = Color(0xFF064232); // one source of truth for both bars
const double kMaxContentWidth = 980.0;

class ShipperManageLoadsScreen extends StatefulWidget {
  const ShipperManageLoadsScreen({super.key});

  @override
  State<ShipperManageLoadsScreen> createState() => _ShipperManageLoadsScreenState();
}

class _ShipperManageLoadsScreenState extends State<ShipperManageLoadsScreen>
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ================= Top section =================
              TopNavigationBar(context),

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
                      GestureDetector(
                        onTap: () {
                          //show dialog
                          showDialog(
                            context: context,
                            builder: (context) {
                              return  ShipperDashboardPostLoad();
                            },
                          );
                        },
                        child: Row(
                          children: [
                            _buildMainButton(
                              '+ Post Loads',
                              const Color(0xFFFFCF5F),
                              Colors.black,
                                  () {
                                //show dialog
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return  ShipperDashboardPostLoad();
                                  },
                                );
                              }
                            ),
                            const SizedBox(width: 15),
                            _buildMainButton(
                              'Booked Loads',
                              const Color(0xFF195529),
                              Colors.white,
    (){
                              // Navigate to Booked Loads screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ShipperBookedLoads(), // Replace with actual Booked Loads screen
                                ),
                              );
    }
                            ),
                          ],
                        ),
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

      );
  }

  // ================= Widgets =================


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
            GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FilterManageLoadScreen(), // Replace with actual Booked Loads screen
                    ),
                  );
                },
                child: SvgPicture.asset('assets/filter_2.svg')),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildMainButton(String text, Color bgColor, Color textColor, Function? Function() onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap
        ,
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
