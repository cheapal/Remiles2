import 'package:flutter/material.dart';
import '../services/app_version_service.dart';
import '../modules/auth/pages/update_required_screen.dart';
import '../modules/auth/pages/maintenance_mode_screen.dart';
import 'auth_wrapper.dart';
import 'app_config.dart';

/// Wrapper that checks app version and maintenance mode before allowing app access
class AppCheckWrapper extends StatefulWidget {
  const AppCheckWrapper({super.key});

  @override
  State<AppCheckWrapper> createState() => _AppCheckWrapperState();
}

class _AppCheckWrapperState extends State<AppCheckWrapper> {
  bool _isChecking = true;
  bool _isMaintenanceMode = false;
  bool _isUpdateRequired = false;

  @override
  void initState() {
    super.initState();
    _performChecks();
    // Store current version in Firestore (non-blocking)
    _storeCurrentVersion();
    // Periodically re-check if in maintenance mode
    _startPeriodicCheck();
  }

  /// Store current app version in Firestore (runs in background, doesn't block app)
  Future<void> _storeCurrentVersion() async {
    try {
      await AppVersionService.storeCurrentVersionInFirestore();
    } catch (e) {
      // Silently fail - this is not critical
      if (AppConfig.enableDebugLogging) {
        print('AppCheckWrapper: Error storing version: $e');
      }
    }
  }

  void _startPeriodicCheck() {
    // Check every 30 seconds if in maintenance mode or update required
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && (_isMaintenanceMode || _isUpdateRequired)) {
        _performChecks();
        _startPeriodicCheck(); // Schedule next check
      }
    });
  }

  Future<void> _performChecks() async {
    try {
      if (AppConfig.enableDebugLogging) {
        print('AppCheckWrapper: Starting checks...');
      }
      
      // First check maintenance mode (highest priority)
      final isMaintenance = await AppVersionService.isMaintenanceMode();
      
      if (AppConfig.enableDebugLogging) {
        print('AppCheckWrapper: Maintenance mode check result: $isMaintenance');
      }
      
      if (isMaintenance) {
        if (mounted) {
          setState(() {
            _isMaintenanceMode = true;
            _isUpdateRequired = false; // Reset update required if maintenance is on
            _isChecking = false;
          });
        }
        if (AppConfig.enableDebugLogging) {
          print('AppCheckWrapper: Maintenance mode is ON, showing maintenance screen');
        }
        // Continue periodic checks while in maintenance
        if (mounted) {
          _startPeriodicCheck();
        }
        return;
      }

      // Maintenance mode is off, reset the flag
      if (_isMaintenanceMode && mounted) {
        setState(() {
          _isMaintenanceMode = false;
        });
      }

      // Then check if update is required
      final isUpdateRequired = await AppVersionService.isUpdateRequired();
      
      if (AppConfig.enableDebugLogging) {
        print('AppCheckWrapper: Update required check result: $isUpdateRequired');
      }
      
      if (isUpdateRequired) {
        if (mounted) {
          setState(() {
            _isUpdateRequired = true;
            _isChecking = false;
          });
        }
        if (AppConfig.enableDebugLogging) {
          print('AppCheckWrapper: Update is REQUIRED, showing update screen');
        }
        // Continue periodic checks while update is required
        if (mounted) {
          _startPeriodicCheck();
        }
        return;
      }

      // Update is no longer required, reset the flag
      if (_isUpdateRequired && mounted) {
        setState(() {
          _isUpdateRequired = false;
        });
      }

      // All checks passed, allow app to continue
      if (AppConfig.enableDebugLogging) {
        print('AppCheckWrapper: All checks passed, allowing app to continue');
      }
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e, stackTrace) {
      if (AppConfig.enableDebugLogging) {
        print('AppCheckWrapper: Error during checks: $e');
        print('AppCheckWrapper: Stack trace: $stackTrace');
      }
      // On error, allow app to continue (fail gracefully)
      // But log the error for debugging
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking
    if (_isChecking) {
      return const LoadingScreen(
        message: 'Checking app status...',
      );
    }

    // Show maintenance mode screen
    if (_isMaintenanceMode) {
      return const MaintenanceModeScreen();
    }

    // Show update required screen
    if (_isUpdateRequired) {
      return const UpdateRequiredScreen();
    }

    // All checks passed, proceed to auth wrapper
    return const AuthWrapper();
  }
}

// Loading screen widget (reused from auth_wrapper)
class LoadingScreen extends StatelessWidget {
  final String? message;
  
  const LoadingScreen({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEF6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/remiles.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B744F)),
            ),
            
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
