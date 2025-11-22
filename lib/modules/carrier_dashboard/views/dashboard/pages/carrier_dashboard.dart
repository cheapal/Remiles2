import 'package:Remiles/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/auth_provider.dart';
import '../../common/widgets/top_navigation_bar.dart';
import '../../common/widgets/recommended_load.dart';
import 'manage_load.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/load_model.dart';
import 'dart:io';

class CarrierDashboardScreen extends StatefulWidget {
  const CarrierDashboardScreen({super.key});

  @override
  State<CarrierDashboardScreen> createState() => _CarrierDashboardScreenState();
}

class _CarrierDashboardScreenState extends State<CarrierDashboardScreen> {
  final primaryColor = Color(0xFF1C6B4A);
  
  // State management for recommended loads
  List<LoadModel> _recommendedLoads = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadRecommendedLoads();
  }
  
  Future<void> _loadRecommendedLoads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final user = FirebaseService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }
      
      final result = await FirebaseService.getAvailableLoadsForCarrier(
        carrierUid: user.uid,
        searchQuery: '',
        limit: 1, // Show only top match
      );
      
      setState(() {
        _recommendedLoads = List<LoadModel>.from(result['loads']);
        _isLoading = false;
      });
    } catch (e) {
      String errorMessage;
      if (e is SocketException || e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = 'Failed to load recommended loads.';
      }
      
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final carrier = authProvider.carrierUser;
        
        // Use company name if available, otherwise use display name, otherwise fallback to 'User'
        final displayName = carrier?.companyName ?? 
                           user?.displayName ?? 
                           'User';
        
        return _buildDashboard(context, displayName);
      },
    );
  }
  
  Widget _buildDashboard(BuildContext context, String displayName) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          /// Fixed Header Section (Top Nav, Welcome, Action Buttons)
          Column(
            children: [
              /// Top Navigation Bar
              TopNavigationBar(context),

              const SizedBox(height: 20),

              /// Welcome Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Welcome\n$displayName",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:  [
                        SvgPicture.asset('assets/eco.svg',
                            width: 50, height: 50,),

                        SizedBox(width: 20),
                        SvgPicture.asset('assets/person.svg',
                            width: 75, height: 65,),
                        SizedBox(width: 20),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// Action Buttons
              Padding(
                padding: const EdgeInsets.only(left:15, right: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellowColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 42, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageLoadScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Find Loads",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 42, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "\$ Payment",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),

          /// Scrollable Content Section (from Carrier Preferences onwards)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// Carrier Preferences
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:  [
                        Text(
                          "Carrier Preferences",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ManageLoadScreen(),
                              ),
                            );
                          },
                          child: SvgPicture.asset('assets/filter.svg',
                              width: 20, height: 20, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Recommended Loads Section (only top match)
                  _buildRecommendedLoadsSection(),
                  const SizedBox(height: 20),

                  /// View All Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 26),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageLoadScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1CAFFF),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text("View All", style: TextStyle(color: Colors.black,fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Stats Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: const BorderRadius.all(
                          Radius.circular(26)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6CA78A)
                              .withOpacity(0.5),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFBFF497),
                              ),
                              child:  Center(
                                child:Icon(Icons.attach_money_outlined),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '2000',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight
                                        .bold, // Updated font weight
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Total Revenue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight
                                .bold, // Updated font weight
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: const BorderRadius.all(
                          Radius.circular(26)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6CA78A)
                              .withOpacity(0.5),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration:  BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFE0B3),
                              ),
                              child:  Center(
                                child: Icon(Icons.check),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '50',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight
                                        .bold, // Updated font weight
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Loads Delivered',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight
                                .bold, // Updated font weight
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statCard(Icons.card_giftcard, "", "Special Offers"),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: const BorderRadius.all(
                          Radius.circular(26)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6CA78A)
                              .withOpacity(0.5),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              child:  Center(
                                child:Icon(Icons.star, color: Colors.amber, ),
                              ),
                            ),
                            const SizedBox(width: 0),
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "3.8/5",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight
                                        .bold, // Updated font weight
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Carrier Ratings",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight
                                .bold, // Updated font weight
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 80), // space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CA78A)
                .withOpacity(0.5),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(

              child: Icon(icon, color: Colors.green, size: 28)),
          const SizedBox(height: 4),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14,  fontWeight: FontWeight.bold,color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedLoadsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadRecommendedLoads,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendedLoads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No recommended loads available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check back later for new opportunities',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show only the top recommended load (highest match percentage)
    if (_recommendedLoads.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: RecommendedLoad(load: _recommendedLoads.first),
      );
    }
    
    return const SizedBox.shrink();
  }

}
