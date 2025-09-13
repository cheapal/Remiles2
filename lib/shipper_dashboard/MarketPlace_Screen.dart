import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ===== Brand + layout constants (reuse across screens) =====
const Color brandColor = Color(0xFF064232); // one source of truth for both bars
const Color brandGreen = Color(0xFF195529);
const double kMaxContentWidth = 980.0;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MarketplaceScreen(),
  ));
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 2; // "Marketplace"
  int _selectedFilter = 0; // 0: All, 1: New, 2: Used, 3: Refurbished
  bool _isLoading = true;

  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    // Simulate loading state (replace with your real data fetch)
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final bool isWide = screenW >= 900;
    final double horizontalPadding =
    screenW > kMaxContentWidth ? (screenW - kMaxContentWidth) / 2 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                // ===== Top bar (brand color, leather only on narrow) =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 5,
                        spreadRadius: 2,
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
                    child: _buildTopBar(isWide),
                  ),
                ),

                // ===== Content =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 100 : 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),

                        // Title row with inline "+ Create listing" on the right
                        Row(
                          children: [
                            const Text(
                              'Marketplace',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                color: Colors.black,
                                height: 1.1,
                              ),
                            ),
                            const Spacer(),
                            _pill(
                              text: '+ Create listing',
                              bg: brandColor,
                              fg: const Color(0xFFFFFBDF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Full-width search bar
                        _searchBar(),

                        const SizedBox(height: 16),

                        // Filters row (All/New/Used/Refurbished)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip('All', 0,
                                  activeBg: brandGreen, activeFg: Colors.white),
                              const SizedBox(width: 10),
                              _filterChip('New', 1),
                              const SizedBox(width: 10),
                              _filterChip('Used', 2),
                              const SizedBox(width: 10),
                              _filterChip('Refurbished', 3, width: 120),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Location + Today’s Picks
                        Row(
                          children: const [
                            Text(
                              "Today's Picks",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: Colors.black,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.place, size: 20, color: brandColor),
                            SizedBox(width: 6),
                            Text(
                              'Vancouver',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: brandGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Grid of ads (skeleton while loading)
                        _adsGrid(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ===== Bottom nav (same brand color as top; leather only on narrow) =====
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Container(
          height: 100,
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
              onTap: (i) => setState(() => _selectedTab = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFFFFBDF),
              unselectedItemColor: const Color(0xFFFFFBDF).withOpacity(0.6),
              selectedLabelStyle: const TextStyle(fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home, size: 26), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart, size: 29),
                    label: 'Manage Loads'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.storefront, size: 30.82),
                    label: 'Marketplace'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person, size: 31.37), label: 'Profile'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.more_horiz, size: 25), label: 'More'),
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
      // WEB/DESKTOP: single Row with logo left and icons right (inline)
      return Row(
        children: [
          Image.asset('assets/remileswhite.png', height: 60),
          const Spacer(),
          _topIcon(Icons.message, 'Messages'),
          const SizedBox(width: 16),
          _topIcon(Icons.notifications, 'Notifications'),
          const SizedBox(width: 16),
          _topIcon(Icons.settings, 'Activity'),
        ],
      );
    } else {
      // MOBILE/TABLET: Wrap for nicer stacking on narrow widths
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Image.asset('assets/remileswhite.png', height: 60),
          _topIcon(Icons.message, 'Messages'),
          _topIcon(Icons.notifications, 'Notifications'),
          _topIcon(Icons.settings, 'Activity'),
        ],
      );
    }
  }

  // Top icon + label (shared identity)
  Widget _topIcon(IconData icon, String label) {
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

  // Search bar (matches app styling)
  Widget _searchBar() {
    return Container(
      height: 36,
      width: double.infinity,
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
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search trucks, trailers, parts ....',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF959595),
                ),
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.filter_list, size: 18, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // Pills (used for create listing etc.)
  Widget _pill({
    required String text,
    required Color bg,
    required Color fg,
    EdgeInsetsGeometry padding =
    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(25, 85, 41, 0.36),
            blurRadius: 2.8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          height: 1.2,
        ),
      ),
    );
  }

  // Filter chip row item
  Widget _filterChip(
      String text,
      int index, {
        Color activeBg = Colors.white,
        Color activeFg = Colors.black,
        double width = 70,
      }) {
    final bool isActive = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        width: width,
        height: 31,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(18.2),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(25, 85, 41, 0.36),
              blurRadius: 2.8,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? activeFg : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  // Ads grid using skeletons while loading
  Widget _adsGrid() {
    final double screenW = MediaQuery.of(context).size.width;

    // Responsive column count
    final int crossAxisCount = screenW >= 1280
        ? 5
        : screenW >= 1000
        ? 4
        : screenW >= 720
        ? 3
        : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 184 / 169, // match design rectangles
      ),
      itemBuilder: (context, i) {
        if (_isLoading) {
          return Shimmer(
            controller: _shimmerCtrl,
            baseColor: const Color(0xFFE8E8E8),
            highlightColor: const Color(0xFFF5F5F5),
            child: _SkeletonAdCard(),
          );
        }
        // Demo listing card (replace with your real data card)
        return const _AdCard(
          title: 'Steel Ramps',
          price: '\$ 1,250',
          city: 'Burnaby, BC',
          tag: 'New',
        );
      },
    );
  }
}

/// A beautiful ad card following the market design sizing & shadows
class _AdCard extends StatelessWidget {
  const _AdCard({
    required this.title,
    required this.price,
    required this.city,
    required this.tag,
  });

  final String title;
  final String price;
  final String city;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2), // prevent shadow clipping
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CA78A).withOpacity(0.20),
            blurRadius: 13.4,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFD9D9D9),
                child: const Icon(Icons.image, size: 34, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // tag + price row
                  Row(
                    children: [
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tag == 'New'
                              ? brandGreen
                              : const Color(0xFF386544),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: const TextStyle(
                          color: Color(0xFFCEB838),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: const [
                      Icon(Icons.place, size: 14, color: Color(0xFF386544)),
                      SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'Burnaby, BC',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: brandGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton version of ad card, with sub-elements for a richer effect.
class _SkeletonAdCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CA78A).withOpacity(0.20),
            blurRadius: 13.4,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image area skeleton
            Expanded(child: Container(color: const Color(0xFFD9D9D9))),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _line(width: 40, height: 16, radius: 8),
                      const Spacer(),
                      _line(width: 58, height: 14, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _line(width: double.infinity, height: 14, radius: 6),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _line(width: 90, height: 12, radius: 6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line({required double width, required double height, double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Lightweight shimmer without external packages.
class Shimmer extends StatelessWidget {
  const Shimmer({
    super.key,
    required this.child,
    required this.controller,
    this.baseColor = const Color(0xFFEAEAEA),
    this.highlightColor = const Color(0xFFF7F7F7),
  });

  final Widget child;
  final AnimationController controller;
  final Color baseColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Move gradient from left to right
        final double slide = (controller.value * 2) - 1; // -1 .. 1
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1 - slide, 0),
              end: Alignment(1 - slide, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.2, 0.5, 0.8],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}
