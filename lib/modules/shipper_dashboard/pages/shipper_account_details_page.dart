import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../core/firebase_service.dart';

class ShipperAccountDetailsPage extends StatefulWidget {
  const ShipperAccountDetailsPage({super.key});

  @override
  State<ShipperAccountDetailsPage> createState() => _ShipperAccountDetailsPageState();
}

class _ShipperAccountDetailsPageState extends State<ShipperAccountDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controllers for editable fields
  late TextEditingController _displayNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _companyNameController;
  late TextEditingController _businessTypeController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final shipper = context.read<AuthProvider>().shipperUser;
    
    _displayNameController = TextEditingController(text: shipper?.displayName ?? '');
    _phoneNumberController = TextEditingController(text: shipper?.phoneNumber ?? '');
    _companyNameController = TextEditingController(text: shipper?.companyName ?? '');
    _businessTypeController = TextEditingController(text: shipper?.businessType ?? '');
    _addressController = TextEditingController(text: shipper?.address ?? '');
    _cityController = TextEditingController(text: shipper?.city ?? '');
    _stateController = TextEditingController(text: shipper?.state ?? '');
    _zipCodeController = TextEditingController(text: shipper?.zipCode ?? '');
    _emailController = TextEditingController(text: shipper?.email ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
    _businessTypeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final appStateProvider = context.read<AppStateProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper == null) {
        throw Exception('Shipper not found');
      }

      appStateProvider.showLoadingWithMessage('Updating profile...');

      // Prepare updates
      final updates = <String, dynamic>{
        if (_displayNameController.text != (shipper.displayName ?? ''))
          'displayName': _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
        if (_phoneNumberController.text != (shipper.phoneNumber ?? ''))
          'phoneNumber': _phoneNumberController.text.trim().isEmpty ? null : _phoneNumberController.text.trim(),
        if (_companyNameController.text != shipper.companyName)
          'companyName': _companyNameController.text.trim().isEmpty ? '' : _companyNameController.text.trim(),
        if (_businessTypeController.text != (shipper.businessType ?? ''))
          'businessType': _businessTypeController.text.trim().isEmpty ? null : _businessTypeController.text.trim(),
        if (_addressController.text != (shipper.address ?? ''))
          'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        if (_cityController.text != (shipper.city ?? ''))
          'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        if (_stateController.text != (shipper.state ?? ''))
          'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        if (_zipCodeController.text != (shipper.zipCode ?? ''))
          'zipCode': _zipCodeController.text.trim().isEmpty ? null : _zipCodeController.text.trim(),
      };

      // Only update if there are changes
      if (updates.isNotEmpty) {
        await FirebaseService.updateShipper(shipper.uid, updates);
        
        // Refresh user data in AuthProvider
        await authProvider.refreshUser();
        
        appStateProvider.showSuccess();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Color(0xFF4B744F),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        appStateProvider.clearLoading();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No changes to save'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to update profile. Please try again.');
      print('Error updating profile: $e');
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
    final shipper = context.watch<AuthProvider>().shipperUser;

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
          'Account Details',
          style: TextStyle(
            color: Color(0xFF186230),
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: shipper == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Name
                    _buildTextField(
                      label: 'Display Name',
                      controller: _displayNameController,
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email (Read-only)
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.email,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneNumberController,
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Company Name
                    _buildTextField(
                      label: 'Company Name',
                      controller: _companyNameController,
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a company name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Business Type
                    _buildTextField(
                      label: 'Business Type',
                      controller: _businessTypeController,
                      icon: Icons.category,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    _buildTextField(
                      label: 'Address',
                      controller: _addressController,
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),

                    // City
                    _buildTextField(
                      label: 'City',
                      controller: _cityController,
                      icon: Icons.location_city,
                    ),
                    const SizedBox(height: 16),

                    // State
                    _buildTextField(
                      label: 'State/Province',
                      controller: _stateController,
                      icon: Icons.map,
                    ),
                    const SizedBox(height: 16),

                    // Zip Code
                    _buildTextField(
                      label: 'Zip Code',
                      controller: _zipCodeController,
                      icon: Icons.pin,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
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
                                'Save Changes',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        color: enabled ? Colors.black87 : Colors.grey,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF186230),
          fontFamily: 'Roboto',
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF186230)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }
}

