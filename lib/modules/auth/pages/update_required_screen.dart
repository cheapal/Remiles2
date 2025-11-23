import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/app_version_service.dart';

class UpdateRequiredScreen extends StatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  String? _appStoreUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppStoreUrl();
  }

  Future<void> _loadAppStoreUrl() async {
    try {
      final urls = await AppVersionService.getAppStoreUrls();
      setState(() {
        if (Platform.isIOS) {
          _appStoreUrl = urls['iosUrl'];
        } else if (Platform.isAndroid) {
          _appStoreUrl = urls['androidUrl'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openAppStore() async {
    if (_appStoreUrl != null && _appStoreUrl!.isNotEmpty) {
      final uri = Uri.parse(_appStoreUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open app store. Please update manually.'),
            ),
          );
        }
      }
    } else {
      // Fallback URLs
      String fallbackUrl;
      if (Platform.isIOS) {
        // You'll need to replace this with your actual App Store URL
        fallbackUrl = 'https://apps.apple.com/app/remiles';
      } else {
        // You'll need to replace this with your actual Play Store URL
        fallbackUrl = 'https://play.google.com/store/apps/details?id=com.example.majh';
      }
      
      final uri = Uri.parse(fallbackUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open app store. Please update manually.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFFEFEF6),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
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
                
                  
                  // // Info icon
                  // Icon(
                  //   Icons.info_outline,
                  //   size: 48,
                  //   color: const Color(0xFF4B744F).withOpacity(0.5),
                  // ),
                  //    const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'Update Required',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  const Text(
                    'A new version of Remiles is available. Please update to the latest version to continue using the app.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Update button
                  if (!_isLoading)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openAppStore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B744F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Update Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  if (_isLoading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B744F)),
                    ),
                  
                 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
