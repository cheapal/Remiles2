import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/firebase_service.dart';
import '../../models/carrier_onboarding_data.dart';
import 'carrier_onboarding_1.dart';
import '../carrier_dashboard/views/dashboard/pages/main_page.dart';
import '../carrier_dashboard/views/dashboard/pages/carrier_dashboard_1.dart';

class CarrierOnboardingWrapper extends StatefulWidget {
  const CarrierOnboardingWrapper({Key? key}) : super(key: key);

  @override
  State<CarrierOnboardingWrapper> createState() => _CarrierOnboardingWrapperState();
}

class _CarrierOnboardingWrapperState extends State<CarrierOnboardingWrapper> {
  bool _isLoading = true;
  bool _isOnboardingComplete = false;
  CarrierOnboardingData? _onboardingData;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;
      
      if (carrier != null) {
        // Get detailed onboarding data from Firebase
        final onboardingData = await FirebaseService.getCarrierOnboardingData(carrier.uid);
        
        setState(() {
          _onboardingData = onboardingData;
          _isOnboardingComplete = carrier.isOnboardingComplete && (onboardingData?.isCompleted ?? false);
          _isLoading = false;
        });
      } else {
        // If no carrier user, go to dashboard (fallback)
        setState(() {
          _isOnboardingComplete = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking onboarding status: $e');
      setState(() {
        _isOnboardingComplete = true; // Default to complete on error
        _isLoading = false;
      });
    }
  }


  Future<void> _markOnboardingComplete() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;
      
      if (carrier != null) {
        // Mark onboarding as complete in Firebase
        await FirebaseService.markCarrierOnboardingComplete(carrier.uid);
        
        // Update the local carrier model
        final updatedOnboardingData = _onboardingData?.markComplete() ?? CarrierOnboardingData().markComplete();
        final updatedCarrier = carrier.copyWithCarrier(
          isOnboardingComplete: true,
          onboardingData: updatedOnboardingData,
        );
        authProvider.setUserData(authProvider.firebaseUser, updatedCarrier);
        
        print('Onboarding marked as complete');
        
        // Check if dashboard steps are completed
        final isDashboardComplete = await FirebaseService.isCarrierDashboardComplete(carrier.uid);
        
        // Navigate to appropriate screen and clear the navigation stack
        if (mounted) {
          if (isDashboardComplete) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainPage()),
              (route) => false, // Remove all previous routes including onboarding
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CarrierDashboard1()),
              (route) => false, // Remove all previous routes including onboarding
            );
          }
        }
      }
    } catch (e) {
      print('Error marking onboarding complete: $e');
    }
  }


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
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isOnboardingComplete) {
      // Onboarding is complete, check dashboard completion
      return _CarrierDashboardCheck();
    } else {
      // Always start from the first screen, but it will be pre-filled with saved responses
      return CarrierOnboarding1Screen(
        onOnboardingComplete: _markOnboardingComplete,
      );
    }
  }
}

/// Widget that checks dashboard completion and navigates accordingly
class _CarrierDashboardCheck extends StatefulWidget {
  const _CarrierDashboardCheck();

  @override
  State<_CarrierDashboardCheck> createState() => _CarrierDashboardCheckState();
}

class _CarrierDashboardCheckState extends State<_CarrierDashboardCheck> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkDashboardCompletion();
  }

  Future<void> _checkDashboardCompletion() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;
      
      if (carrier != null) {
        final isDashboardComplete = await FirebaseService.isCarrierDashboardComplete(carrier.uid);
        
        if (mounted) {
          if (isDashboardComplete) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainPage()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CarrierDashboard1()),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CarrierDashboard1()),
          );
        }
      }
    } catch (e) {
      print('Error checking dashboard completion: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CarrierDashboard1()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFFEFEF6),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B744F)),
          ),
        ),
      );
    }
    
    // This should not be reached, but just in case
    return const CarrierDashboard1();
  }
}
