import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/app_settings_page.dart';
import 'package:remiles/modules/shipper_dashboard/pages/profile_document_management.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_boost_my_page.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_my_preference.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_payment_page.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_account_details_page.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_settings_page.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_help_legal_page.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../providers/payment_methods_provider.dart';
import '../../../providers/carrier_payments_provider.dart';
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
      final imageUrl = await FirebaseService.uploadShipperProfileImage(
        shipper.uid,
        image,
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
      appStateProvider.showError(
        'Failed to update profile picture. Please try again.',
      );
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

  Future<void> _deleteProfilePicture() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final appStateProvider = context.read<AppStateProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper == null) {
        throw Exception('Shipper not found');
      }

      if (shipper.profileImageUrl == null || shipper.profileImageUrl!.isEmpty) {
        return; // No image to delete
      }

      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Delete Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF186230),
              ),
            ),
            content: const Text(
              'Are you sure you want to delete your profile picture?',
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldDelete != true) {
        return;
      }

      setState(() {
        _isUploadingImage = true;
      });

      appStateProvider.showLoadingWithMessage('Deleting profile picture...');

      // Try to delete the file from Firebase Storage
      try {
        await FirebaseService.deleteFileFromURL(shipper.profileImageUrl!);
      } catch (e) {
        // Log error but continue - the file might not exist or already be deleted
        print('Error deleting file from storage: $e');
      }

      // Update shipper profile to remove image URL
      await FirebaseService.updateShipper(shipper.uid, {
        'profileImageUrl': null,
      });

      // Refresh user data
      await authProvider.refreshUser();

      appStateProvider.showSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture deleted successfully'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError(
        'Failed to delete profile picture. Please try again.',
      );
      print('Error deleting profile picture: $e');

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
      backgroundColor: backgroundColor, //const Color(0xFFF5F7FA),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: CustomScrollView(
          slivers: [
            // Top Navigation
            SliverToBoxAdapter(child: TopNavigationBar(context)),

            // Profile Header with Gradient
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1C6B4A),
                      const Color(0xFF43975A),
                      const Color(0xFF81AB3A),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTabletOrDesktop ? 100.0 : 20.0,
                    vertical: 30,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Profile Picture
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 3,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _isUploadingImage
                                ? null
                                : _changeProfilePicture,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipOval(
                                    child: shipper?.profileImageUrl != null
                                        ? Image.network(
                                            shipper!.profileImageUrl!,
                                            width: 130,
                                            height: 130,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: 130,
                                                    height: 130,
                                                    decoration:
                                                        const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Color(
                                                            0xFFF5F7FA,
                                                          ),
                                                        ),
                                                    child: const Icon(
                                                      Icons.person,
                                                      size: 80,
                                                      color: Color(0xFF43975A),
                                                    ),
                                                  );
                                                },
                                          )
                                        : Container(
                                            width: 130,
                                            height: 130,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFF5F7FA),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              size: 80,
                                              color: Color(0xFF43975A),
                                            ),
                                          ),
                                  ),
                                  if (_isUploadingImage)
                                    Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (!_isUploadingImage)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: _changeProfilePicture,
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF43975A),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                          if (shipper?.profileImageUrl !=
                                                  null &&
                                              shipper!
                                                  .profileImageUrl!
                                                  .isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: _deleteProfilePicture,
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 3,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Company Name
                      Text(
                        shipper?.companyName ?? 'Company Name',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      if (shipper != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatChip(
                              icon: Icons.star_rounded,
                              value: shipper.rating != null
                                  ? '${shipper.rating!.toStringAsFixed(1)}'
                                  : 'N/A',
                              color: const Color(0xFFFDD610),
                            ),
                            const SizedBox(width: 12),
                            _buildVerifiedChip(
                              isVerified:
                                  (shipper.isVerified ||
                                  shipper.isPhoneVerified),
                            ),
                            const SizedBox(width: 12),
                            _buildStatChip(
                              icon: Icons.local_shipping_rounded,
                              value: _isLoadingStats
                                  ? '...'
                                  : '${_completedShipments ?? shipper.totalShipments}',
                              color: Colors.white,
                              isLoading: _isLoadingStats,
                            ),
                          ],
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isTabletOrDesktop ? 100.0 : 20.0,
                vertical: 24,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Cards
                  if (shipper != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star_rounded,
                            label: 'Rating',
                            value: shipper.rating != null
                                ? '${shipper.rating!.toStringAsFixed(1)}'
                                : 'N/A',
                            color: const Color(0xFFFDD610),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.local_shipping_rounded,
                            label: 'Shipments',
                            value: _isLoadingStats
                                ? '...'
                                : '${_completedShipments != null ? _completedShipments : shipper.totalShipments}',
                            color: const Color(0xFF43975A),
                            isLoading: _isLoadingStats,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Account Settings',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // Profile Options
                  _buildModernProfileOption(
                    'Account Details',
                    Icons.account_circle_rounded,
                    'Manage your personal information',
                    () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ShipperAccountDetailsPage(),
                        ),
                      );
                      _loadShipperStats();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModernProfileOption(
                    'Payment Method',
                    Icons.payment_rounded,
                    'Manage payment methods',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModernProfileOption(
                    'Load Preferences',
                    Icons.tune_rounded,
                    'Customize your load preferences',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ShipperDashboardMyPreferencePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModernProfileOption(
                    'Documents',
                    Icons.description_rounded,
                    'Manage your documents',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProfileDocumentManagment(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModernProfileOption(
                    'Boost My Load',
                    Icons.rocket_launch_rounded,
                    'Promote your loads',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShipperBoostMyPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Support & More',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  _buildModernProfileOption(
                    'Settings',
                    Icons.settings_rounded,
                    'App settings and preferences',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShipperSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // App Settings - only visible in debug mode
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    _buildModernProfileOption(
                      'App Settings',
                      Icons.admin_panel_settings_rounded,
                      'Developer settings',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppSettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                  _buildModernProfileOption(
                    'Help & Legal',
                    Icons.help_outline_rounded,
                    'Get help and view legal info',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShipperHelpLegalPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showLogoutDialog(context),
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          isLoading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildVerifiedChip({required bool isVerified}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified
            ? const Color(0xFF81AB3A).withOpacity(0.3)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified
              ? const Color(0xFF81AB3A)
              : Colors.white.withOpacity(0.3),
          width: isVerified ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isVerified
                  ? const Color(0xFF81AB3A)
                  : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 6),
          Text(
            isVerified ? 'Verified' : 'Unverified',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isVerified ? Colors.white : Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildModernProfileOption(
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF43975A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF43975A), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
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
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
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
    final paymentMethodsProvider = context.read<PaymentMethodsProvider>();
    final carrierPaymentsProvider = context.read<CarrierPaymentsProvider>();

    try {
      appStateProvider.showLoadingWithMessage('Logging out...');

      // Clear payment-related providers before logout
      paymentMethodsProvider.clear();
      carrierPaymentsProvider.clear();

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
