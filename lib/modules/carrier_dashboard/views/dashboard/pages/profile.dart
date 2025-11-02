import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/app_state_provider.dart';
import '../../../../../core/auth_wrapper.dart';
import '../../../../../core/firebase_service.dart';
import '../../common/widgets/top_navigation_bar.dart';
import 'carrier_preferences.dart';
import 'account_details_page.dart';
import 'settings_page.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  int? _completedOrders;
  bool _isLoadingStats = true;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadCarrierStats();
  }

  Future<void> _loadCarrierStats() async {
    final authProvider = context.read<AuthProvider>();
    final carrier = authProvider.carrierUser;
    
    if (carrier != null) {
      try {
        final bookedLoads = await FirebaseService.getCarrierBookedLoads(
          carrierUid: carrier.uid,
          status: 'completed',
        );
        if (mounted) {
          setState(() {
            _completedOrders = bookedLoads['loads']?.length ?? 0;
            _isLoadingStats = false;
          });
        }
      } catch (e) {
        print('Error loading carrier stats: $e');
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
      final carrier = authProvider.carrierUser;

      if (carrier == null) {
        throw Exception('Carrier not found');
      }

      appStateProvider.showLoadingWithMessage('Uploading profile picture...');

      // Upload image to Firebase Storage
      final imageFile = File(image.path);
      final imageUrl = await FirebaseService.uploadCarrierProfileImage(
        carrier.uid,
        imageFile,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Update carrier profile with new image URL
      await FirebaseService.updateCarrier(carrier.uid, {
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
    final authProvider = context.watch<AuthProvider>();
    final carrier = authProvider.carrierUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          TopNavigationBar(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Profile Header
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 130),
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
                              carrier?.companyName ?? carrier?.companyName ?? 'Company Name',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Color(0xFF186230),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
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
                              child: carrier?.profileImageUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        carrier!.profileImageUrl!,
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
                if (carrier != null)
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
                            carrier.rating != null
                                ? '${carrier.rating!.toStringAsFixed(1)}'
                                : 'N/A',
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: carrier.rating != null ? Colors.black87 : Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Verified Badge - always show
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: carrier.isVerified
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
                            carrier.isVerified ? 'Verified' : 'Unverified',
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: carrier.isVerified ? Colors.black87 : Colors.grey),
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
                                  '${_completedOrders ?? carrier.totalDeliveries ?? 0}',
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
                      builder: (context) => const AccountDetailsPage(),
                    ),
                  );
                  // Refresh stats when returning from Account Details
                  _loadCarrierStats();
                }),
                const SizedBox(height: 16),
                _buildProfileOption('Payment Method', Icons.credit_card, () {}),
                const SizedBox(height: 16),
                _buildProfileOption('Load Preferences', Icons.tune, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CarrierPreferencesPage(),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                _buildProfileOption('Documents', Icons.description, () {}),
                const SizedBox(height: 16),
                _buildProfileOption('Boost My Load', Icons.rocket_launch, () {}),
                const SizedBox(height: 16),
                _buildProfileOption('Settings', Icons.settings, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                _buildProfileOption('Help & Legal', Icons.help_outline, () {}),
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
      
      print('Logout successful, navigating to AuthWrapper');
      
      // Navigate directly to AuthWrapper which will handle the welcome screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      appStateProvider.showError('Logout failed. Please try again.');
      print('Logout error: $e');
    }
  }
}

Widget _buildProfileOption(String text, IconData icon, VoidCallback onTap) {
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
