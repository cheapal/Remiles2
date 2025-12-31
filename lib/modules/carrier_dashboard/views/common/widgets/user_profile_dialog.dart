import 'package:flutter/material.dart';
import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/models/shipper_model.dart';
import 'package:remiles/models/carrier_model.dart';
import 'package:remiles/models/user_model.dart';

class UserProfileDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final UserRole? userRole; // null means we need to detect it
  final VoidCallback? onReport; // Callback for report button

  const UserProfileDialog({
    super.key,
    required this.userId,
    required this.userName,
    this.userRole,
    this.onReport,
  });

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  bool _isLoading = true;
  ShipperModel? _shipper;
  CarrierModel? _carrier;
  Map<String, int>? _loadStats;
  int? _completedOrders;
  UserRole? _detectedRole;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Try to get as shipper first
      final shipper = await FirebaseService.getShipper(widget.userId);
      if (shipper != null) {
        setState(() {
          _shipper = shipper;
          _detectedRole = UserRole.shipper;
        });
        // Load shipper load stats
        final stats = await FirebaseService.getShipperLoadStats(widget.userId);
        setState(() {
          _loadStats = stats;
        });
      } else {
        // Try as carrier
        final carrier = await FirebaseService.getCarrier(widget.userId);
        if (carrier != null) {
          setState(() {
            _carrier = carrier;
            _detectedRole = UserRole.carrier;
          });
          // Load carrier bookings count (completed orders)
          try {
            final bookedLoads = await FirebaseService.getCarrierBookedLoads(
              carrierUid: widget.userId,
              status: 'completed',
            );
            setState(() {
              _completedOrders = bookedLoads['loads']?.length ?? 0;
            });
          } catch (e) {
            print('Error loading carrier bookings: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleReport() {
    Navigator.of(context).pop(); // Close profile dialog
    if (widget.onReport != null) {
      widget.onReport!(); // Call the report callback from chat screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShipper = _detectedRole == UserRole.shipper || widget.userRole == UserRole.shipper;
    final isCarrier = _detectedRole == UserRole.carrier || widget.userRole == UserRole.carrier;
    final user = _shipper ?? _carrier;
    final isVerified = (isShipper && ((_shipper?.isVerified ?? false) || (_shipper?.isPhoneVerified ?? false))) ||
        (isCarrier && ((_carrier?.isVerified ?? false) || (_carrier?.isPhoneVerified ?? false)));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'User Profile',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6CA78A).withOpacity(0.2),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: primaryColor.withOpacity(0.1),
                              backgroundImage: user?.profileImageUrl != null
                                  ? NetworkImage(user!.profileImageUrl!)
                                  : null,
                              child: user?.profileImageUrl == null
                                  ? Icon(Icons.person, size: 50, color: primaryColor)
                                  : null,
                            ),
                            // Verification Badge
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isVerified ? const Color(0xFF81AB3A) : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Role and Verification Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isShipper ? Icons.local_shipping : Icons.directions_car,
                              size: 18,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isShipper ? 'Shipper' : 'Carrier',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isVerified ? const Color(0xFF81AB3A) : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 9,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVerified ? 'Verified' : 'Unverified',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isVerified ? Colors.black87 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        // Rating
                        if ((isShipper && _shipper?.rating != null) ||
                            (isCarrier && _carrier?.rating != null)) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 20,
                                color: Color(0xFFFDD610),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (isShipper ? _shipper!.rating : _carrier!.rating)!
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Verification Status Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6CA78A).withOpacity(0.15),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verification Status',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildVerificationItem(
                          'Account Verification',
                          isShipper ? (_shipper?.isVerified ?? false) : (_carrier?.isVerified ?? false),
                        ),
                        const SizedBox(height: 8),
                        _buildVerificationItem(
                          'Phone Verification',
                          isShipper ? (_shipper?.isPhoneVerified ?? false) : (_carrier?.isPhoneVerified ?? false),
                        ),
                        const SizedBox(height: 8),
                        _buildVerificationItem(
                          'Email Verification',
                          user?.isEmailVerified ?? false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Company/Business Information Card
                  if ((isShipper && _shipper != null) || (isCarrier && _carrier != null))
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6CA78A).withOpacity(0.15),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isShipper ? 'Company Information' : 'Business Information',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isShipper && _shipper != null) ...[
                            _buildModernInfoRow(Icons.business, 'Company Name', _shipper!.companyName),
                            if (_shipper!.businessType != null)
                              _buildModernInfoRow(Icons.category, 'Business Type', _shipper!.businessType!),
                            if (_shipper!.address != null || _shipper!.city != null)
                              _buildModernInfoRow(
                                Icons.location_on,
                                'Address',
                                [
                                  _shipper!.address,
                                  _shipper!.city,
                                  _shipper!.state,
                                  _shipper!.zipCode,
                                ].where((e) => e != null).join(', '),
                              ),
                          ] else if (isCarrier && _carrier != null) ...[
                            if (_carrier!.companyName != null)
                              _buildModernInfoRow(Icons.business, 'Company Name', _carrier!.companyName!),
                            if (_carrier!.businessType != null)
                              _buildModernInfoRow(Icons.category, 'Business Type', _carrier!.businessType!),
                            if (_carrier!.address != null || _carrier!.city != null)
                              _buildModernInfoRow(
                                Icons.location_on,
                                'Address',
                                [
                                  _carrier!.address,
                                  _carrier!.city,
                                  _carrier!.state,
                                  _carrier!.zipCode,
                                ].where((e) => e != null).join(', '),
                              ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Statistics Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6CA78A).withOpacity(0.15),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistics',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isShipper && _loadStats != null) ...[
                          _buildModernStatCard(
                            Icons.local_shipping,
                            'Total Shipments',
                            _loadStats!['total']?.toString() ?? '0',
                            primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildModernStatCard(
                            Icons.check_circle,
                            'Completed Shipments',
                            _loadStats!['completed']?.toString() ?? '0',
                            const Color(0xFF81AB3A),
                          ),
                          const SizedBox(height: 12),
                          _buildModernStatCard(
                            Icons.inventory,
                            'Active Loads',
                            _loadStats!['active']?.toString() ?? '0',
                            Colors.orange,
                          ),
                        ] else if (isCarrier && _carrier != null) ...[
                          _buildModernStatCard(
                            Icons.delivery_dining,
                            'Total Deliveries',
                            _carrier!.totalDeliveries?.toString() ?? '0',
                            primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildModernStatCard(
                            Icons.check_circle,
                            'Completed Orders',
                            _completedOrders?.toString() ?? '0',
                            const Color(0xFF81AB3A),
                          ),
                          const SizedBox(height: 12),
                          _buildModernStatCard(
                            _carrier!.isAvailable ? Icons.verified_user : Icons.block,
                            'Status',
                            _carrier!.isAvailable ? 'Available' : 'Not Available',
                            _carrier!.isAvailable ? const Color(0xFF81AB3A) : Colors.grey,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Equipment/Vehicle Types (Carriers)
                  if (isCarrier && _carrier != null && _carrier!.vehicleTypes != null && _carrier!.vehicleTypes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6CA78A).withOpacity(0.15),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Equipment',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _carrier!.vehicleTypes!.map((type) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Service Areas/Routes (Carriers)
                  if (isCarrier && _carrier != null && _carrier!.serviceAreas != null && _carrier!.serviceAreas!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6CA78A).withOpacity(0.15),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Areas',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _carrier!.serviceAreas!.map((area) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Text(
                                  area,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Preferred Carrier Types (Shippers)
                  if (isShipper && _shipper != null && _shipper!.preferredCarrierTypes != null && _shipper!.preferredCarrierTypes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6CA78A).withOpacity(0.15),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preferred Carrier Types',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _shipper!.preferredCarrierTypes!.map((type) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Colors.orange.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Contact Information Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6CA78A).withOpacity(0.15),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (user?.email != null)
                          _buildModernInfoRow(Icons.email, 'Email', user!.email),
                        if (user?.phoneNumber != null) ...[
                          if (user?.email != null) const SizedBox(height: 12),
                          _buildModernInfoRow(Icons.phone, 'Phone', user!.phoneNumber!),
                        ],
                      ],
                    ),
                  ),

                  // Report Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _handleReport,
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text(
                          'Report User',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.shade300, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildVerificationItem(String label, bool status) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: status ? const Color(0xFF81AB3A) : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            status ? Icons.check : Icons.close,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          status ? 'Verified' : 'Not Verified',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: status ? const Color(0xFF81AB3A) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(IconData icon, String label, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

