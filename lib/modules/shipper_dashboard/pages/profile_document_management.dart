import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/modules/shipper_dashboard/pages/profile_doc_upload.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Remiles/providers/auth_provider.dart';
import 'package:Remiles/models/user_model.dart';
import 'package:intl/intl.dart';

class ProfileDocumentManagment extends StatefulWidget {
  const ProfileDocumentManagment({super.key});

  @override
  State<ProfileDocumentManagment> createState() =>
      _ProfileDocumentManagmentState();
}

class _ProfileDocumentManagmentState extends State<ProfileDocumentManagment> {
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<_DocItem> _allDocs = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userRole = authProvider.userRole;

      final List<_DocItem> docs = [];

      if (userRole == UserRole.carrier) {
        final carrier = authProvider.carrierUser;
        if (carrier != null) {
          final dashboard2 = await FirebaseService.getCarrierDashboardResponse(
            carrier.uid,
            'dashboard_2_business_info',
          );
          final dashboard3 = await FirebaseService.getCarrierDashboardResponse(
            carrier.uid,
            'dashboard_3_business_number',
          );

          // Map of key -> url
          final d2 = dashboard2 ?? {};
          final d3 = dashboard3 ?? {};

          // Parse expiry dates
          DateTime? commercialExpiry = _parseDate(d2['commercialExpiryDate']);

          docs.addAll([
            _DocItem(
              id: 'driversLicenseUrl',
              title: 'Drivers License (Front & Back)',
              category: 'Safety',
              uploaded: (d2['driversLicenseUrl'] ?? '').toString().isNotEmpty,
              expiryDate: null,
            ),
            _DocItem(
              id: 'vehicleRegistrationUrl',
              title: 'Vehicle Registration',
              category: 'Safety',
              uploaded:
                  (d2['vehicleRegistrationUrl'] ?? '').toString().isNotEmpty,
              expiryDate: null,
            ),
            _DocItem(
              id: 'nscUrl',
              title: 'NSC (National Safety Code)',
              category: 'Safety',
              uploaded: (d2['nscUrl'] ?? '').toString().isNotEmpty,
              expiryDate: null,
            ),
            _DocItem(
              id: 'proofOfInsuranceUrl',
              title: 'Proof of Insurance',
              category: 'Proof of Insurance',
              uploaded:
                  (d2['proofOfInsuranceUrl'] ?? '').toString().isNotEmpty,
              expiryDate: commercialExpiry,
            ),
            _DocItem(
              id: 'driversAbstractUrl',
              title: 'Drivers Abstract',
              category: 'Safety',
              uploaded:
                  (d3['driversAbstractUrl'] ?? '').toString().isNotEmpty,
              expiryDate: null,
            ),
            _DocItem(
              id: 'backgroundCheckUrl',
              title: 'Background Check',
              category: 'Safety',
              uploaded:
                  (d3['backgroundCheckUrl'] ?? '').toString().isNotEmpty,
              expiryDate: null,
            ),
          ]);
        }
      } else if (userRole == UserRole.shipper) {
        final shipper = authProvider.shipperUser;
        if (shipper != null) {
          final dashboard2 = await FirebaseService.getShipperDashboardResponse(
            shipper.uid,
            'dashboard_2_business_info',
          );
          final d2 = dashboard2 ?? {};

          // Parse expiry date
          DateTime? insuranceExpiry = _parseDate(d2['expiryDate']);

          docs.addAll([
            _DocItem(
              id: 'businessRegistrationUrl',
              title: 'Business License',
              category: 'Business License',
              uploaded:
                  (d2['businessRegistrationUrl'] ?? '').toString().isNotEmpty,
              expiryDate: null,
            ),
            _DocItem(
              id: 'insuranceDocumentUrl',
              title: 'Cargo Insurance',
              category: 'Cargo Insurance',
              uploaded:
                  (d2['insuranceDocumentUrl'] ?? '').toString().isNotEmpty,
              expiryDate: insuranceExpiry,
            ),
          ]);
        }
      }

      if (mounted) {
        setState(() {
          _allDocs = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<_DocItem> get _filteredDocs {
    Iterable<_DocItem> docs = _allDocs;

    // Apply filter chip
    switch (_selectedFilter) {
      case 'Proof of Delivery':
        // No direct aggregated POD docs yet, so show none for now
        docs = const Iterable<_DocItem>.empty();
        break;
      case 'Proof of Insurance':
      case 'Safety':
      case 'Tax':
      case 'Business License':
      case 'Cargo Insurance':
        docs = docs.where((d) => d.category == _selectedFilter);
        break;
      case 'Active':
        docs = docs.where((d) => d.uploaded && !d.isExpired);
        break;
      case 'Pending':
        docs = docs.where((d) => !d.uploaded);
        break;
      case 'Expired':
        docs = docs.where((d) => d.isExpired);
        break;
      case 'All':
      default:
        break;
    }

    // Apply search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      docs = docs.where(
        (d) => d.title.toLowerCase().contains(q),
      );
    }

    return docs.toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userRole;
    final isShipper = userRole == UserRole.shipper;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
               // Top Navigation Bar
                  TopNavigationBar(context),
            Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Document Management System',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search Box
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search by Document Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfileDocUpload(),
                          ),
                        );
                      },
                      child: const Text(
                        "+ Upload",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Buttons - Show different filters based on role
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip("All"),
                      if (!isShipper) ...[
                        _buildFilterChip("Proof of Delivery"),
                        _buildFilterChip("Proof of Insurance"),
                        _buildFilterChip("Safety"),
                        _buildFilterChip("Tax"),
                      ],
                      if (isShipper) ...[
                        _buildFilterChip("Business License"),
                        _buildFilterChip("Cargo Insurance"),
                      ],
                      _buildFilterChip("Active"),
                      _buildFilterChip("Expired"),
                      _buildFilterChip("Pending"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_filteredDocs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No documents found for the selected filters.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final doc in _filteredDocs) ...[
                          _buildDocumentCard(
                            title: doc.title,
                            subtitle: _buildSubtitle(doc),
                            actions: [
                              _buildActionButton(
                                doc.uploaded ? "Manage" : "Upload",
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool selected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: Colors.blue.shade100,
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required List<Widget> actions,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: actions
                    .map(
                      (btn) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: btn,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(_DocItem doc) {
    if (!doc.uploaded) {
      return 'Status: Pending upload';
    }
    
    if (doc.isExpired) {
      final expiryStr = doc.expiryDate != null
          ? DateFormat('MM/dd/yyyy').format(doc.expiryDate!)
          : 'Unknown';
      return 'Status: Expired\nExpired on: $expiryStr';
    }
    
    if (doc.expiryDate != null) {
      final expiryStr = DateFormat('MM/dd/yyyy').format(doc.expiryDate!);
      return 'Status: Active\nExpires on: $expiryStr';
    }
    
    return 'Status: Active';
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().isEmpty) {
      return null;
    }
    
    final dateStr = dateValue.toString();
    
    // Try MM/dd/yyyy format (from date picker)
    try {
      final format = DateFormat('MM/dd/yyyy');
      return format.parse(dateStr);
    } catch (e) {
      // Try other common formats
      try {
        return DateTime.parse(dateStr);
      } catch (e2) {
        print('Failed to parse date: $dateStr');
        return null;
      }
    }
  }

  Widget _buildActionButton(String text) {
    return OutlinedButton(
      onPressed: () {
        // Always navigate to the unified document upload/management screen.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileDocUpload(),
          ),
        );
      },
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _DocItem {
  final String id;
  final String title;
  final String category;
  final bool uploaded;
  final DateTime? expiryDate;

  const _DocItem({
    required this.id,
    required this.title,
    required this.category,
    required this.uploaded,
    this.expiryDate,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }
}
