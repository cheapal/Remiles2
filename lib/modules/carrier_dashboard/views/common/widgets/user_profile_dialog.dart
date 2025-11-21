import 'package:flutter/material.dart';
import 'package:Remiles/core/theme/colors.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/shipper_model.dart';
import 'package:Remiles/models/carrier_model.dart';
import 'package:Remiles/models/user_model.dart';

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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500,
        ),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with avatar and name
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: primaryColor.withOpacity(0.2),
                            backgroundImage: user?.profileImageUrl != null
                                ? NetworkImage(user!.profileImageUrl!)
                                : null,
                            child: user?.profileImageUrl == null
                                ? Icon(Icons.person, size: 40, color: primaryColor)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isShipper ? Icons.local_shipping : Icons.directions_car,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isShipper ? 'Shipper' : 'Carrier',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if ((isShipper && ((_shipper?.isVerified ?? false) || (_shipper?.isPhoneVerified ?? false))) ||
                                        (isCarrier && ((_carrier?.isVerified ?? false) || (_carrier?.isPhoneVerified ?? false)))) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if ((isShipper && _shipper?.rating != null) ||
                                    (isCarrier && _carrier?.rating != null)) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (isShipper ? _shipper!.rating : _carrier!.rating)!
                                            .toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company/Business Info
                          if (isShipper && _shipper != null) ...[
                            _buildSectionTitle('Company Information'),
                            _buildInfoRow('Company Name', _shipper!.companyName),
                            if (_shipper!.businessType != null)
                              _buildInfoRow('Business Type', _shipper!.businessType!),
                            if (_shipper!.address != null || _shipper!.city != null)
                              _buildInfoRow(
                                'Address',
                                [
                                  _shipper!.address,
                                  _shipper!.city,
                                  _shipper!.state,
                                  _shipper!.zipCode,
                                ].where((e) => e != null).join(', '),
                              ),
                            const SizedBox(height: 16),
                          ] else if (isCarrier && _carrier != null) ...[
                            _buildSectionTitle('Business Information'),
                            if (_carrier!.companyName != null)
                              _buildInfoRow('Company Name', _carrier!.companyName!),
                            if (_carrier!.businessType != null)
                              _buildInfoRow('Business Type', _carrier!.businessType!),
                            if (_carrier!.address != null || _carrier!.city != null)
                              _buildInfoRow(
                                'Address',
                                [
                                  _carrier!.address,
                                  _carrier!.city,
                                  _carrier!.state,
                                  _carrier!.zipCode,
                                ].where((e) => e != null).join(', '),
                              ),
                            const SizedBox(height: 16),
                          ],

                          // Statistics
                          _buildSectionTitle('Statistics'),
                          if (isShipper && _loadStats != null) ...[
                            _buildStatCard('Total Shipments', _loadStats!['total']?.toString() ?? '0'),
                            _buildStatCard('Completed Shipments', _loadStats!['completed']?.toString() ?? '0'),
                            _buildStatCard('Active Loads', _loadStats!['active']?.toString() ?? '0'),
                          ] else if (isCarrier && _carrier != null) ...[
                            _buildStatCard('Total Deliveries', _carrier!.totalDeliveries?.toString() ?? '0'),
                            _buildStatCard('Completed Orders', _completedOrders?.toString() ?? '0'),
                            _buildStatCard(
                              'Status',
                              _carrier!.isAvailable ? 'Available' : 'Not Available',
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Equipment/Vehicle Types (Carriers)
                          if (isCarrier && _carrier != null && _carrier!.vehicleTypes != null && _carrier!.vehicleTypes!.isNotEmpty) ...[
                            _buildSectionTitle('Equipment'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _carrier!.vehicleTypes!.map((type) {
                                return Chip(
                                  label: Text(type),
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  labelStyle: TextStyle(color: primaryColor, fontSize: 12),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Service Areas/Routes (Carriers)
                          if (isCarrier && _carrier != null && _carrier!.serviceAreas != null && _carrier!.serviceAreas!.isNotEmpty) ...[
                            _buildSectionTitle('Service Areas'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _carrier!.serviceAreas!.map((area) {
                                return Chip(
                                  label: Text(area),
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Preferred Carrier Types (Shippers)
                          if (isShipper && _shipper != null && _shipper!.preferredCarrierTypes != null && _shipper!.preferredCarrierTypes!.isNotEmpty) ...[
                            _buildSectionTitle('Preferred Carrier Types'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _shipper!.preferredCarrierTypes!.map((type) {
                                return Chip(
                                  label: Text(type),
                                  backgroundColor: Colors.orange.withOpacity(0.1),
                                  labelStyle: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Contact Information
                          _buildSectionTitle('Contact Information'),
                          if (user?.email != null) _buildInfoRow('Email', user!.email),
                          if (user?.phoneNumber != null)
                            _buildInfoRow('Phone', user!.phoneNumber!),
                          const SizedBox(height: 16),

                          // Report Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleReport,
                              icon: const Icon(Icons.flag_outlined),
                              label: const Text('Report User'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

