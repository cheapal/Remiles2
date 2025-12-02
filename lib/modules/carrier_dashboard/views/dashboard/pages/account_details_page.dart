import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/app_state_provider.dart';
import '../../../../../core/firebase_service.dart';
import '../../../../../core/utils/google_places_autocomplete.dart';
import '../../../../../core/utils/multi_select_dialog.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controllers for editable fields
  late TextEditingController _displayNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _companyNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _emailController;
  
  // Business type multi-select
  List<String> _selectedBusinessTypes = [];
  
  // Phone number availability checking
  Timer? _phoneCheckTimer;
  bool _isCheckingPhone = false;
  String? _phoneAvailabilityMessage;
  bool? _isPhoneAvailable;
  
  // Business type options
  static const List<String> _businessTypeOptions = [
    'Manufacturing',
    'Retail',
    'Agriculture',
    'Construction',
    'Food & Beverage',
    'Healthcare',
    'Technology',
    'Automotive',
    'Textiles',
    'Chemicals',
    'Mining',
    'Energy',
    'Logistics & Transportation',
    'E-commerce',
    'Other',
  ];
  
  // Google Places API Key
  static const String _googleApiKey = 'AIzaSyAOZKD90SxW5dwOZVEe-nCm8dA6jXs-5AQ';

  @override
  void initState() {
    super.initState();
    final carrier = context.read<AuthProvider>().carrierUser;
    
    _displayNameController = TextEditingController(text: carrier?.displayName ?? '');
    _phoneNumberController = TextEditingController(text: carrier?.phoneNumber ?? '');
    _companyNameController = TextEditingController(text: carrier?.companyName ?? '');
    _addressController = TextEditingController(text: carrier?.address ?? '');
    _cityController = TextEditingController(text: carrier?.city ?? '');
    _stateController = TextEditingController(text: carrier?.state ?? '');
    _zipCodeController = TextEditingController(text: carrier?.zipCode ?? '');
    _emailController = TextEditingController(text: carrier?.email ?? '');
    
    // Parse business type from string to list
    if (carrier?.businessType != null && carrier!.businessType!.isNotEmpty) {
      _selectedBusinessTypes = carrier.businessType!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    
    // Add listener for phone number changes
    _phoneNumberController.addListener(_onPhoneNumberChanged);
  }
  
  void _onPhoneNumberChanged() {
    // Cancel previous timer
    _phoneCheckTimer?.cancel();
    
    final phoneNumber = _phoneNumberController.text.trim();
    
    // Clear previous message if field is empty
    if (phoneNumber.isEmpty) {
      setState(() {
        _phoneAvailabilityMessage = null;
        _isPhoneAvailable = null;
        _isCheckingPhone = false;
      });
      return;
    }
    
    // Don't check if it's the same as current phone number
    final carrier = context.read<AuthProvider>().carrierUser;
    if (phoneNumber == (carrier?.phoneNumber ?? '')) {
      setState(() {
        _phoneAvailabilityMessage = null;
        _isPhoneAvailable = null;
        _isCheckingPhone = false;
      });
      return;
    }
    
    // Debounce: wait 500ms after user stops typing
    _phoneCheckTimer = Timer(const Duration(milliseconds: 500), () {
      _checkPhoneAvailability(phoneNumber);
    });
  }
  
  Future<void> _checkPhoneAvailability(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return;
    
    setState(() {
      _isCheckingPhone = true;
      _phoneAvailabilityMessage = null;
      _isPhoneAvailable = null;
    });
    
    try {
      final carrier = context.read<AuthProvider>().carrierUser;
      final isAvailable = await FirebaseService.isPhoneNumberAvailable(
        phoneNumber: phoneNumber,
        excludeUid: carrier?.uid,
      );
      
      if (mounted) {
        setState(() {
          _isCheckingPhone = false;
          _isPhoneAvailable = isAvailable;
          if (isAvailable) {
            _phoneAvailabilityMessage = 'Phone number is available';
          } else {
            _phoneAvailabilityMessage = 'Phone number is already in use';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingPhone = false;
          _phoneAvailabilityMessage = 'Error checking availability';
          _isPhoneAvailable = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneCheckTimer?.cancel();
    _phoneNumberController.removeListener(_onPhoneNumberChanged);
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
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
      final carrier = authProvider.carrierUser;

      if (carrier == null) {
        throw Exception('Carrier not found');
      }

      appStateProvider.showLoadingWithMessage('Updating profile...');

      // Prepare business type string
      final businessTypeString = _selectedBusinessTypes.join(', ');
      final currentBusinessType = carrier.businessType ?? '';
      
      // Check if phone number has changed
      final newPhoneNumber = _phoneNumberController.text.trim();
      final currentPhoneNumber = carrier.phoneNumber ?? '';
      final phoneNumberChanged = newPhoneNumber != currentPhoneNumber;
      
      // Prepare updates
      final updates = <String, dynamic>{
        if (_displayNameController.text != carrier.displayName)
          'displayName': _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
        if (phoneNumberChanged)
          'phoneNumber': newPhoneNumber.isEmpty ? null : newPhoneNumber,
        if (phoneNumberChanged)
          'isPhoneVerified': false, // Reset verification status when phone number changes
        if (_companyNameController.text != carrier.companyName)
          'companyName': _companyNameController.text.trim().isEmpty ? null : _companyNameController.text.trim(),
        if (businessTypeString != currentBusinessType)
          'businessType': _selectedBusinessTypes.isEmpty ? null : businessTypeString,
        if (_addressController.text != carrier.address)
          'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        if (_cityController.text != carrier.city)
          'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        if (_stateController.text != carrier.state)
          'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        if (_zipCodeController.text != carrier.zipCode)
          'zipCode': _zipCodeController.text.trim().isEmpty ? null : _zipCodeController.text.trim(),
      };

      // Only update if there are changes
      if (updates.isNotEmpty) {
        await FirebaseService.updateCarrier(carrier.uid, updates);
        
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
    final carrier = context.watch<AuthProvider>().carrierUser;

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
      body: carrier == null
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
                    _buildPhoneNumberField(),
                    const SizedBox(height: 16),

                    // Company Name
                    _buildTextField(
                      label: 'Company Name',
                      controller: _companyNameController,
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 16),

                    // Business Type (Multi-select)
                    MultiSelectField(
                      hintText: 'Business Type',
                      icon: Icons.category,
                      selectedItems: _selectedBusinessTypes,
                      title: 'Select Business Type(s)',
                      options: _businessTypeOptions,
                      onSelectionChanged: (List<String> selected) {
                        setState(() {
                          _selectedBusinessTypes = selected;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address (Google Places Autocomplete)
                    GooglePlacesAutocomplete(
                      controller: _addressController,
                      hintText: 'Address',
                      icon: Icons.location_on,
                      apiKey: _googleApiKey,
                      onAddressComponents: (AddressComponents components) {
                        setState(() {
                          if (components.address != null) {
                            _addressController.text = components.address!;
                          }
                          if (components.city != null) {
                            _cityController.text = components.city!;
                          }
                          if (components.state != null) {
                            _stateController.text = components.state!;
                          }
                          if (components.zipCode != null) {
                            _zipCodeController.text = components.zipCode!;
                          }
                        });
                      },
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

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _phoneNumberController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Colors.black87,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a phone number';
            }
            if (_isPhoneAvailable == false) {
              return 'Phone number is already in use';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Phone Number',
            labelStyle: const TextStyle(
              color: Color(0xFF186230),
              fontFamily: 'Roboto',
            ),
            prefixIcon: const Icon(Icons.phone, color: Color(0xFF186230)),
            suffixIcon: _isCheckingPhone
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF186230)),
                      ),
                    ),
                  )
                : _isPhoneAvailable != null
                    ? Icon(
                        _isPhoneAvailable! ? Icons.check_circle : Icons.error,
                        color: _isPhoneAvailable! ? Colors.green : Colors.red,
                      )
                    : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _isPhoneAvailable == false ? Colors.red : const Color(0xFF43975A),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _isPhoneAvailable == false ? Colors.red : const Color(0xFF43975A),
                width: 2,
              ),
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
            fillColor: Colors.white,
          ),
        ),
        if (_phoneAvailabilityMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              _phoneAvailabilityMessage!,
              style: TextStyle(
                fontSize: 12,
                color: _isPhoneAvailable == true ? Colors.green : Colors.red,
                fontFamily: 'Roboto',
              ),
            ),
          ),
      ],
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

