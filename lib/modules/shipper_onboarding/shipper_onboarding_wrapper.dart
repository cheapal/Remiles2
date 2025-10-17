import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/firebase_service.dart';
import '../../models/shipper_onboarding_data.dart';
import '../shipper_dashboard/pages/shipper_dashboard_4_main_page.dart';
import 'shipper_onboarding_1.dart';

class ShipperOnboardingWrapper extends StatefulWidget {
  const ShipperOnboardingWrapper({super.key});

  @override
  State<ShipperOnboardingWrapper> createState() => _ShipperOnboardingWrapperState();
}

class _ShipperOnboardingWrapperState extends State<ShipperOnboardingWrapper> {
  bool _isLoading = true;
  bool _isOnboardingComplete = false;
  ShipperOnboardingData? _onboardingData;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper != null) {
        final onboardingData = await FirebaseService.getShipperOnboardingData(shipper.uid);
        setState(() {
          _onboardingData = onboardingData;
          _isOnboardingComplete = shipper.isOnboardingComplete && (onboardingData?.isCompleted ?? false);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isOnboardingComplete = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isOnboardingComplete = true;
        _isLoading = false;
      });
    }
  }

  // removed unused _markOnboardingComplete

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFEFEF6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B744F)),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      );
    }

    if (_isOnboardingComplete) {
      return const ShipperDashboardMainPage();
    }

    return const ShipperOnboarding1Screen();
  }
}


