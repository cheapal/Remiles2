import 'package:Remiles/modules/auth/pages/splash.dart';
import 'package:Remiles/modules/auth/pages/welcome.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_boost_my_page.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_my_preference.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_payment_page.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_profile_document_management.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_account_details_page.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_settings_page.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/shipper_help_legal_page.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../core/auth_wrapper.dart';
import '../../../core/firebase_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class ShipperProfile extends StatefulWidget {
  const ShipperProfile({super.key});

  @override
  State<ShipperProfile> createState() => _ShipperProfileState();
}

class _ShipperProfileState extends State<ShipperProfile>
    with TickerProviderStateMixin {
  int? _completedShipments;
  bool _isLoadingStats = true;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadShipperStats();
  }

  Future<void> _loadShipperStats() async {
    final authProvider = context.read<AuthProvider>();
    final shipper = authProvider.shipperUser;
    
    if (shipper != null) {
      try {
        final stats = await FirebaseService.getShipperLoadStats(shipper.uid);
        if (mounted) {
          setState(() {
            _completedShipments = stats['completed'] ?? 0;
            _isLoadingStats = false;
          });
        }
      } catch (e) {
        print('Error loading shipper stats: $e');
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final authProvider = context.read<AuthProvider>();
      final appStateProvider = context.read<AppStateProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper == null) {
        throw Exception('Shipper not found');
      }

      appStateProvider.showLoadingWithMessage('Uploading profile picture...');

      // Upload image to Firebase Storage
      final imageFile = File(image.path);
      final imageUrl = await FirebaseService.uploadShipperProfileImage(
        shipper.uid,
        imageFile,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Update shipper profile with new image URL
      await FirebaseService.updateShipper(shipper.uid, {
        'profileImageUrl': imageUrl,
      });

      // Refresh user data
      await authProvider.refreshUser();

      appStateProvider.showSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to update profile picture. Please try again.');
      print('Error updating profile picture: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTabletOrDesktop = MediaQuery.of(context).size.width > 600;
    final authProvider = context.watch<AuthProvider>();
    final shipper = authProvider.shipperUser;

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
              TopNavigationBar(context),

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
                            const SizedBox(height: 120),
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
                              child: Center(
                                child: Text(
                                  shipper?.companyName ?? 'Company Name',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Color(0xFF186230),
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _isUploadingImage ? null : _changeProfilePicture,
                          child: Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF43975A),
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: shipper?.profileImageUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            shipper!.profileImageUrl!,
                                            width: 98,
                                            height: 98,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 98,
                                                height: 98,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFFFFFEF6),
                                                ),
                                                child: const Icon(Icons.person, size: 70, color: Color(0xFF43975A)),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          width: 98,
                                          height: 98,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFFFFEF6),
                                          ),
                                          child: const Icon(Icons.person, size: 70, color: Color(0xFF43975A)),
                                        ),
                                ),
                                if (_isUploadingImage)
                                  Container(
                                    width: 106,
                                    height: 106,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!_isUploadingImage)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF43975A),
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Ratings and Shipments
                    if (shipper != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Star Rating - always show
                            const Icon(Icons.star, color: Color(0xFFFDD610), size: 16),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                shipper.rating != null
                                    ? '${shipper.rating!.toStringAsFixed(1)}'
                                    : 'N/A',
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: shipper.rating != null ? Colors.black87 : Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Verified Badge - always show (based on account or phone verification)
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: (shipper.isVerified || shipper.isPhoneVerified)
                                    ? const Color(0xFF81AB3A)
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 9,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                (shipper.isVerified || shipper.isPhoneVerified) ? 'Verified' : 'Unverified',
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: (shipper.isVerified || shipper.isPhoneVerified) ? Colors.black87 : Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Shipments
                            Icon(Icons.local_shipping, size: 16, color: Colors.black87),
                            const SizedBox(width: 4),
                            _isLoadingStats
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Flexible(
                                    child: Text(
                                      '${_completedShipments ?? shipper.totalShipments}',
                                      style: const TextStyle(
                                          fontFamily: 'Roboto',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Profile Options
                    _buildProfileOption('Account Details', Icons.account_circle, () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShipperAccountDetailsPage(),
                        ),
                      );
                      // Refresh stats when returning from Account Details
                      _loadShipperStats();
                    }),
                    const SizedBox(height: 16),
                    _buildProfileOption('Payment Method', Icons.credit_card, () {
                      // Navigate to Payment Method page
                      Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const PaymentMethodsPage())
                      );
                    }),
                    const SizedBox(height: 16),
                    _buildProfileOption('Load Preferences', Icons.tune,(){
                      Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const ShipperDashboardMyPreferencePage())
                      );
                    }),
                    const SizedBox(height: 16),
                    _buildProfileOption('Documents', Icons.description,(){

                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShipperProfileDocumentManagment(),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    _buildProfileOption('Boost My Load', Icons.rocket_launch,(){
//ShipperBoostMyPage
                     Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const ShipperBoostMyPage())
                      );
                    }),
                    const SizedBox(height: 16),
                    _buildProfileOption('Settings', Icons.settings,(){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShipperSettingsPage(),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    _buildProfileOption('Help & Legal', Icons.help_outline,(){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShipperHelpLegalPage(),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Logout button
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context),
                      child: Container(
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

  Widget _buildProfileOption(String text, IconData icon, Function()? onTap ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

  // Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF186230),
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout(context);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF186230),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Handle logout functionality
  void _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final appStateProvider = context.read<AppStateProvider>();

    try {
      appStateProvider.showLoadingWithMessage('Logging out...');
      
      await authProvider.signOut();
      
      appStateProvider.showSuccess();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Color(0xFF4B744F),
          duration: Duration(seconds: 2),
        ),
      );
      
      print('Shipper logout successful, navigating to AuthWrapper');
      
      // Navigate directly to AuthWrapper which will handle the welcome screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      appStateProvider.showError('Logout failed. Please try again.');
      print('Shipper logout error: $e');
    }
  }
}
