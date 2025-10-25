import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/app_state_provider.dart';
import '../../../../../core/auth_wrapper.dart';
import '../../common/widgets/top_navigation_bar.dart';
import 'carrier_preferences.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return   SingleChildScrollView(
      child: Column(
        children: [
          TopNavigationBar(context),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: //isTabletOrDesktop ? 100.0 :
                20.0),
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
                _buildProfileOption('Account Details', Icons.account_circle, () {}),
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
                _buildProfileOption('Settings', Icons.settings, () {}),
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
