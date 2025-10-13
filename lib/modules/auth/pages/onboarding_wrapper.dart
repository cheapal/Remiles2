import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'joiningoption.dart';

// Alias for better naming
typedef JoiningOptionScreen = SignScreen;

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({Key? key}) : super(key: key);

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  bool _isLoading = true;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;
      
      setState(() {
        _isFirstTime = !hasCompletedOnboarding;
        _isLoading = false;
      });
    } catch (e) {
      // If there's an error, assume first time
      setState(() {
        _isFirstTime = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);
      
      setState(() {
        _isFirstTime = false;
      });
    } catch (e) {
      debugPrint('Error saving onboarding status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isFirstTime) {
      return JoiningOptionScreen(
        nextScreen: const SizedBox.shrink(),
        onOnboardingComplete: _completeOnboarding,
      );
    }

    // If onboarding is complete, show the joining options again
    return const JoiningOptionScreen(nextScreen: SizedBox.shrink());
  }
}
