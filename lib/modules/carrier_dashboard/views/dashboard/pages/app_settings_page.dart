import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../providers/app_state_provider.dart';
import '../../../../../core/firebase_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _minVersionController = TextEditingController();
  final _minBuildNumberController = TextEditingController();
  final _maintenanceMessageController = TextEditingController();
  final _iosUrlController = TextEditingController();
  final _androidUrlController = TextEditingController();
  
  bool _isLoading = false;
  bool _isMaintenanceMode = false;
  String _currentAppVersion = '';
  String _currentBuildNumber = '';
  String _storedVersion = '';
  int? _storedBuildNumber;
  String? _lastVersionUpdate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCurrentVersion();
  }

  @override
  void dispose() {
    _minVersionController.dispose();
    _minBuildNumberController.dispose();
    _maintenanceMessageController.dispose();
    _iosUrlController.dispose();
    _androidUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentAppVersion = packageInfo.version;
        _currentBuildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      print('Error loading current version: $e');
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settingsDoc = await FirebaseService.firestore
          .collection('app_settings')
          .doc('settings')
          .get();

      if (settingsDoc.exists) {
        final data = settingsDoc.data()!;
        // Handle build number type conversion (Firestore might return int, num, or String)
        int? minBuildNumber;
        final minBuildNumberValue = data['minBuildNumber'];
        if (minBuildNumberValue != null) {
          if (minBuildNumberValue is int) {
            minBuildNumber = minBuildNumberValue;
          } else if (minBuildNumberValue is num) {
            minBuildNumber = minBuildNumberValue.toInt();
          } else if (minBuildNumberValue is String) {
            minBuildNumber = int.tryParse(minBuildNumberValue);
          }
        }
        
        // Handle stored build number type conversion
        int? storedBuildNumber;
        final storedBuildNumberValue = data['currentBuildNumber'];
        if (storedBuildNumberValue != null) {
          if (storedBuildNumberValue is int) {
            storedBuildNumber = storedBuildNumberValue;
          } else if (storedBuildNumberValue is num) {
            storedBuildNumber = storedBuildNumberValue.toInt();
          } else if (storedBuildNumberValue is String) {
            storedBuildNumber = int.tryParse(storedBuildNumberValue);
          }
        }
        
        setState(() {
          _isMaintenanceMode = data['maintenanceMode'] as bool? ?? false;
          _minVersionController.text = data['minAppVersion'] as String? ?? '';
          _minBuildNumberController.text = minBuildNumber?.toString() ?? '';
          _maintenanceMessageController.text = data['maintenanceMessage'] as String? ?? '';
          _iosUrlController.text = data['iosAppStoreUrl'] as String? ?? '';
          _androidUrlController.text = data['androidPlayStoreUrl'] as String? ?? '';
          _storedVersion = data['currentAppVersion'] as String? ?? '';
          _storedBuildNumber = storedBuildNumber;
          _lastVersionUpdate = data['lastVersionUpdate'] as String?;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showLoadingWithMessage('Saving settings...');

      final updates = <String, dynamic>{
        'maintenanceMode': _isMaintenanceMode,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      if (_minVersionController.text.trim().isNotEmpty) {
        updates['minAppVersion'] = _minVersionController.text.trim();
      } else {
        updates['minAppVersion'] = null;
      }

      if (_minBuildNumberController.text.trim().isNotEmpty) {
        final buildNumber = int.tryParse(_minBuildNumberController.text.trim());
        if (buildNumber != null) {
          updates['minBuildNumber'] = buildNumber;
        } else {
          updates['minBuildNumber'] = null;
        }
      } else {
        updates['minBuildNumber'] = null;
      }

      if (_maintenanceMessageController.text.trim().isNotEmpty) {
        updates['maintenanceMessage'] = _maintenanceMessageController.text.trim();
      } else {
        updates['maintenanceMessage'] = null;
      }

      if (_iosUrlController.text.trim().isNotEmpty) {
        updates['iosAppStoreUrl'] = _iosUrlController.text.trim();
      } else {
        updates['iosAppStoreUrl'] = null;
      }

      if (_androidUrlController.text.trim().isNotEmpty) {
        updates['androidPlayStoreUrl'] = _androidUrlController.text.trim();
      } else {
        updates['androidPlayStoreUrl'] = null;
      }

      await FirebaseService.firestore
          .collection('app_settings')
          .doc('settings')
          .set(updates, SetOptions(merge: true));

      appStateProvider.showSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to save settings');
      print('Error saving settings: $e');
      
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF186230)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'App Settings',
          style: TextStyle(
            color: Color(0xFF186230),
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading && _minVersionController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Version Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'App Version Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Current Running Version
                          const Text(
                            'Currently Running:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version: $_currentAppVersion',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Build Number: $_currentBuildNumber',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          // Stored Version in Firestore
                          if (_storedVersion.isNotEmpty || _storedBuildNumber != null) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Stored in Firestore:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version: ${_storedVersion.isNotEmpty ? _storedVersion : "Not set"}',
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Build Number: ${_storedBuildNumber != null ? _storedBuildNumber.toString() : "Not set"}',
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            if (_lastVersionUpdate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Last Updated: ${_formatDate(_lastVersionUpdate!)}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ] else ...[
                            const SizedBox(height: 8),
                            const Text(
                              'No version stored in Firestore yet',
                              style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Maintenance Mode
                    const Text(
                      'Maintenance Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF186230),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _isMaintenanceMode,
                      onChanged: (value) {
                        setState(() {
                          _isMaintenanceMode = value;
                        });
                      },
                      title: const Text(
                        'Enable Maintenance Mode',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _isMaintenanceMode
                            ? 'App is currently in maintenance mode'
                            : 'App is running normally',
                        style: TextStyle(
                          color: _isMaintenanceMode ? Colors.orange : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                      activeColor: const Color(0xFF4B744F),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maintenanceMessageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Maintenance Message',
                        hintText: 'Enter custom maintenance message (optional)',
                        labelStyle: const TextStyle(
                          color: Color(0xFF186230),
                          fontFamily: 'Roboto',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Minimum Version Requirements
                    const Text(
                      'Minimum Version Requirements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF186230),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _minVersionController,
                      decoration: InputDecoration(
                        labelText: 'Minimum App Version',
                        hintText: 'e.g., 1.0.0',
                        labelStyle: const TextStyle(
                          color: Color(0xFF186230),
                          fontFamily: 'Roboto',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final parts = value.trim().split('.');
                          if (parts.length < 2) {
                            return 'Invalid version format (e.g., 1.0.0)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _minBuildNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Minimum Build Number',
                        hintText: 'e.g., 1',
                        labelStyle: const TextStyle(
                          color: Color(0xFF186230),
                          fontFamily: 'Roboto',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final buildNumber = int.tryParse(value.trim());
                          if (buildNumber == null || buildNumber < 0) {
                            return 'Please enter a valid build number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Users with versions below these values will be forced to update.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // App Store URLs
                    const Text(
                      'App Store URLs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF186230),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _iosUrlController,
                      decoration: InputDecoration(
                        labelText: 'iOS App Store URL',
                        hintText: 'https://apps.apple.com/app/remiles',
                        labelStyle: const TextStyle(
                          color: Color(0xFF186230),
                          fontFamily: 'Roboto',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _androidUrlController,
                      decoration: InputDecoration(
                        labelText: 'Android Play Store URL',
                        hintText: 'https://play.google.com/store/apps/details?id=...',
                        labelStyle: const TextStyle(
                          color: Color(0xFF186230),
                          fontFamily: 'Roboto',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43975A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Settings',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
