import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/custom_progress_bar.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/carrier_model.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'delivery_details_page.dart';

class ShipperLoadDetailsPage extends StatefulWidget {
  final Map<String, dynamic> load;

  const ShipperLoadDetailsPage({
    super.key,
    required this.load,
  });

  @override
  State<ShipperLoadDetailsPage> createState() => _ShipperLoadDetailsPageState();
}

class _ShipperLoadDetailsPageState extends State<ShipperLoadDetailsPage> {
  // Colors matching marketplace_screen.dart
  static const Color green = Color(0xFF2E9340);
  static const Color blue = Color(0xFF2265A6);
  
  // Carrier information
  CarrierModel? _carrier;
  bool _isLoadingCarrier = false;
  String? _carrierPhone;
  
  // Map controller
  GoogleMapController? _mapController;
  
  // Location data
  LatLng? _pickupLocation;
  LatLng? _deliveryLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoadingMap = true;
  String? _mapErrorMessage;
  
  // Firestore reference
  DocumentReference? _loadDocumentRef;
  
  // Expandable state
  bool _isLoadInfoExpanded = false;
  
  // Delivery confirmation data
  Map<String, dynamic>? _deliveryConfirmationData;
  
  @override
  void initState() {
    super.initState();
    _initializeLoadDocument();
    _loadCarrierInfo();
    _loadMapLocations();
    _loadDeliveryConfirmationData(widget.load['id']?.toString());
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  
  void _initializeLoadDocument() {
    final loadId = widget.load['id']?.toString();
    final shipperUid = widget.load['shipperUid']?.toString();
    
    if (loadId != null && shipperUid != null) {
      _loadDocumentRef = FirebaseFirestore.instance
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId);
    }
  }
  
  Future<void> _loadMapLocations() async {
    setState(() {
      _isLoadingMap = true;
      _mapErrorMessage = null;
    });
    
    try {
      final originAddress = widget.load['originAddress']?.toString() ?? '';
      final originCity = widget.load['originCity']?.toString() ?? '';
      final originState = widget.load['originState']?.toString() ?? '';
      final destinationAddress = widget.load['destinationAddress']?.toString() ?? '';
      final destinationCity = widget.load['destinationCity']?.toString() ?? '';
      final destinationState = widget.load['destinationState']?.toString() ?? '';
      
      String pickupAddress = originAddress;
      if (originCity.isNotEmpty) pickupAddress += ', $originCity';
      if (originState.isNotEmpty) pickupAddress += ', $originState';
      
      String deliveryAddress = destinationAddress;
      if (destinationCity.isNotEmpty) deliveryAddress += ', $destinationCity';
      if (destinationState.isNotEmpty) deliveryAddress += ', $destinationState';
      
      if (pickupAddress.isNotEmpty && pickupAddress != ', , ') {
        final pickupLocations = await locationFromAddress(pickupAddress);
        if (pickupLocations.isNotEmpty) {
          _pickupLocation = LatLng(
            pickupLocations.first.latitude,
            pickupLocations.first.longitude,
          );
        }
      }
      
      if (deliveryAddress.isNotEmpty && deliveryAddress != ', , ') {
        final deliveryLocations = await locationFromAddress(deliveryAddress);
        if (deliveryLocations.isNotEmpty) {
          _deliveryLocation = LatLng(
            deliveryLocations.first.latitude,
            deliveryLocations.first.longitude,
          );
        }
      }
      
      if (_pickupLocation != null && _deliveryLocation != null) {
        _createMarkers();
        _fitBoundsToMarkers();
      }
      
      if (mounted) {
        setState(() {
          _isLoadingMap = false;
        });
      }
    } catch (e) {
      print('Error loading map locations: $e');
      if (mounted) {
        setState(() {
          _isLoadingMap = false;
          _mapErrorMessage = 'Failed to load map locations';
        });
      }
    }
  }
  
  void _createMarkers() {
    _markers = {};
    
    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    
    if (_deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation!,
          infoWindow: const InfoWindow(title: 'Delivery Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBoundsToMarkers();
  }
  
  void _fitBoundsToMarkers() {
    if (_mapController == null || _pickupLocation == null || _deliveryLocation == null) {
      return;
    }
    
    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _pickupLocation!.latitude < _deliveryLocation!.latitude
              ? _pickupLocation!.latitude
              : _deliveryLocation!.latitude,
          _pickupLocation!.longitude < _deliveryLocation!.longitude
              ? _pickupLocation!.longitude
              : _deliveryLocation!.longitude,
        ),
        northeast: LatLng(
          _pickupLocation!.latitude > _deliveryLocation!.latitude
              ? _pickupLocation!.latitude
              : _deliveryLocation!.latitude,
          _pickupLocation!.longitude > _deliveryLocation!.longitude
              ? _pickupLocation!.longitude
              : _deliveryLocation!.longitude,
        ),
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {
      print('Error fitting bounds: $e');
    }
  }
  
  Future<void> _loadCarrierInfo([Map<String, dynamic>? loadData]) async {
    final load = loadData ?? widget.load;
    final bookedByCarrierId = load['bookedByCarrierId'];
    if (bookedByCarrierId == null || bookedByCarrierId.toString().isEmpty) {
      if (mounted) {
        setState(() {
          _carrier = null;
          _carrierPhone = null;
          _isLoadingCarrier = false;
        });
      }
      return;
    }
    
    // Don't reload if it's the same carrier
    if (_carrier?.uid == bookedByCarrierId.toString()) {
      return;
    }
    
    setState(() {
      _isLoadingCarrier = true;
    });
    
    try {
      final carrier = await FirebaseService.getCarrier(bookedByCarrierId.toString());
      if (mounted) {
        setState(() {
          _carrier = carrier;
          _carrierPhone = carrier?.phoneNumber;
          _isLoadingCarrier = false;
        });
      }
    } catch (e) {
      print('Error loading carrier info: $e');
      if (mounted) {
        setState(() {
          _isLoadingCarrier = false;
        });
      }
    }
  }
  
  void _makePhoneCall() async {
    if (_carrierPhone == null || _carrierPhone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final uri = Uri.parse('tel:$_carrierPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _navigateToChat() async {
    if (_carrier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carrier information not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final loadId = widget.load['id']?.toString();
    final shipperUid = widget.load['shipperUid']?.toString();
    
    if (loadId == null || shipperUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Load information not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Create or get conversation for load
      final conversationId = await FirebaseService.createLoadConversation(
        loadId: loadId,
        carrierUid: _carrier!.uid,
        shipperUid: shipperUid,
      );
      
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      // Navigate to chat screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserId: _carrier!.uid,
              otherUserName: _carrier!.displayName ?? _carrier!.companyName ?? 'Carrier',
              loadId: loadId,
              loadPrice: widget.load['quoteBudget'] != null 
                  ? (widget.load['quoteBudget'] is num 
                      ? (widget.load['quoteBudget'] as num).toDouble() 
                      : double.tryParse(widget.load['quoteBudget'].toString()) ?? 0.0)
                  : null,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  double _calculateProgress(Map<String, dynamic> load) {
    final status = load['status']?.toString().toLowerCase() ?? '';
    if (status == 'completed') return 1.0;
    if (status == 'in-transit') return 0.75;
    if (status == 'booked') return 0.5;
    return 0.25;
  }

  @override
  Widget build(BuildContext context) {
    final loadId = widget.load['id']?.toString() ?? 'N/A';
    final loadIdShort = loadId.length >= 8 ? loadId.substring(0, 8) : loadId;
    
    // Use StreamBuilder for real-time updates if we have document reference
    if (_loadDocumentRef != null) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _loadDocumentRef!.snapshots(),
          builder: (context, snapshot) {
            Map<String, dynamic> currentLoad = widget.load;
            
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              currentLoad = {
                ...widget.load,
                ...data,
                'id': snapshot.data!.id,
              };
              
              // Load delivery confirmation data if load ID changed
              final currentLoadId = currentLoad['id']?.toString();
              if (currentLoadId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadDeliveryConfirmationData(currentLoadId);
                });
              }
              
              // Update carrier info if bookedByCarrierId changed
              final newCarrierId = currentLoad['bookedByCarrierId']?.toString();
              final currentCarrierId = _carrier?.uid;
              if (newCarrierId != null && newCarrierId != currentCarrierId && newCarrierId.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadCarrierInfo(currentLoad);
                });
              } else if (newCarrierId == null || newCarrierId.isEmpty) {
                // Clear carrier if no longer booked
                if (_carrier != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadCarrierInfo(currentLoad);
                  });
                }
              }
            }
            
            return _buildContent(context, currentLoad, loadIdShort);
          },
        ),
      );
    }
    
    // Fallback if no document reference
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: _buildContent(context, widget.load, loadIdShort),
    );
  }
  
  Widget _buildContent(BuildContext context, Map<String, dynamic> load, String loadIdShort) {
    final status = load['status']?.toString().toLowerCase() ?? '';
    
    return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TopNavigationBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Load Details',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                
                // Load ID Header
                Text(
                  'Load ID #$loadIdShort',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Status Pills
                _buildStatusPills(status),
                const SizedBox(height: 20),
                
                // Load Information (Collapsible)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.25),
                          blurRadius: 13.4,
                          spreadRadius: 0,
                          offset: Offset(0, 13.4),
                        ),
                      ],
                    ),
                  child: Column(
                    children: [
                      // Header (always visible)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isLoadInfoExpanded = !_isLoadInfoExpanded;
                          });
                        },
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Load Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Icon(
                                _isLoadInfoExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.black,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Content (expandable)
                      if (_isLoadInfoExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              const SizedBox(height: 16),
                          _buildDetailRow('Origin', load['originAddress'] ?? 'N/A'),
                          _buildDetailRow('Destination', load['destinationAddress'] ?? 'N/A'),
                          _buildDetailRow('Load Type', load['loadType'] ?? 'N/A'),
                          _buildDetailRow('Load Sensitivity', load['loadSensitivity'] ?? 'N/A'),
                          _buildDetailRow('Description', load['loadDescription'] ?? 'N/A'),
                          _buildDetailRow('Weight', '${load['weight'] ?? 'N/A'} ${load['weightUnit'] ?? 'kg'}'),
                          _buildDetailRow('Dimensions', load['dimensions'] ?? 'N/A'),
                          _buildDetailRow('Equipment Needed', load['equipmentNeeded'] ?? 'N/A'),
                          _buildDetailRow('Declared Value', '${load['declaredValue'] ?? 'N/A'}'),
                          _buildDetailRow('Quote/Budget', '\$${load['quoteBudget'] ?? 'N/A'}'),
                          _buildDetailRow('Pickup Date/Time', _formatDate(load['pickupDateTime'], includeTime: true)),
                          _buildDetailRow('Delivery Window', _formatDeliveryWindow(load)),
                          if (load['additionalDocument'] != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    'Document',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _viewDocument(context, load['additionalDocument']),
                                    icon: const Icon(Icons.visibility, size: 18),
                                    label: const Text('View Document'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF386544),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Google Map
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _isLoadingMap
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(green),
                            ),
                          )
                        : _mapErrorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(height: 8),
                                    Text(
                                      _mapErrorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : _pickupLocation != null && _deliveryLocation != null
                                ? GoogleMap(
                                    onMapCreated: _onMapCreated,
                                    initialCameraPosition: CameraPosition(
                                      target: _pickupLocation!,
                                      zoom: 10.0,
                                    ),
                                    markers: _markers,
                                    polylines: _polylines,
                                    mapType: MapType.normal,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    compassEnabled: false,
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.map_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Map locations not available',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Progress Bar
                CustomProgressBar(value: _calculateProgress(load)),
                const SizedBox(height: 24),
                
                // Carrier Information Card
                if (_carrier != null || _isLoadingCarrier) ...[
                  _buildCarrierCard(),
                  const SizedBox(height: 24),
                ],
                
                // POD Section
                _buildPODSection(load),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
    );
  }
  
  Widget _buildStatusPills(String status) {
    bool enRouteActive = status == 'booked' || status == 'in-transit';
    bool pickupActive = status == 'in-transit' || status == 'completed';
    bool inTransitActive = status == 'in-transit';
    bool deliveredActive = status == 'completed';
    
    return Row(
      children: [
        Expanded(
          child: _StatusPill(
            label: "En Route",
            color: enRouteActive ? green : Colors.grey,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatusPill(
            label: "Pickup",
            color: pickupActive ? green : Colors.grey,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatusPill(
            label: "In Transit",
            color: inTransitActive ? blue : Colors.grey,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatusPill(
            label: "Delivered",
            color: deliveredActive ? green : Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCarrierCard() {
    if (_isLoadingCarrier) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: green, width: 2),
          boxShadow: [
            BoxShadow(
              color: green.withOpacity(0.18),
              blurRadius: 4,
              spreadRadius: 0.5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(green),
          ),
        ),
      );
    }
    
    if (_carrier == null) {
      return const SizedBox.shrink();
    }
    
    final carrierName = _carrier!.displayName ?? _carrier!.companyName ?? 'Unknown Carrier';
    final phoneNumber = _carrierPhone ?? 'N/A';
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: green, width: 2),
              boxShadow: [
                BoxShadow(
                  color: green.withOpacity(0.18),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Carrier",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  carrierName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            IconButton(
              onPressed: _carrierPhone != null && _carrierPhone!.isNotEmpty
                  ? _makePhoneCall
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phone number not available'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
              icon: Icon(
                Icons.phone_rounded,
                color: _carrierPhone != null && _carrierPhone!.isNotEmpty
                    ? green
                    : Colors.grey.shade400,
              ),
              iconSize: 30,
              tooltip: 'Call carrier',
            ),
            const SizedBox(height: 6),
            IconButton(
              onPressed: _carrier != null ? _navigateToChat : null,
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: _carrier != null ? green : Colors.grey.shade400,
              ),
              iconSize: 30,
              tooltip: 'Message carrier',
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPODSection(Map<String, dynamic> load) {
    // Check POD from both load document and delivery confirmation document
    final podUrlFromLoad = load['podUrl'] as String?;
    final podUrlFromConfirmation = _deliveryConfirmationData?['podUrl'] as String?;
    final podUrl = podUrlFromConfirmation ?? podUrlFromLoad;
    final hasPOD = podUrl != null && podUrl.isNotEmpty;
    final hasUnreadPOD = load['hasUnreadPOD'] == true || load['hasUnreadPOD'] == 1;
    // final status = load['status']?.toString().toLowerCase() ?? ''; // Temporarily unused
    // final isDeliveryDone = status == 'in-transit' || status == 'completed'; // Temporarily unused
    final isConfirmed = _deliveryConfirmationData != null;
    
    // Check payment status from Firebase document
    // If paymentAmount is null or paymentReleased is null/false, payment hasn't been done
    final paymentAmount = _deliveryConfirmationData?['paymentAmount'];
    final paymentReleased = _deliveryConfirmationData?['paymentReleased'] == true || 
                           _deliveryConfirmationData?['paymentReleased'] == 1;
    
    // Payment is considered done only if both paymentAmount exists AND paymentReleased is true
    // If paymentAmount is null, payment hasn't been done
    final isPaymentDone = paymentAmount != null && paymentReleased == true;
    
    // Parse payment amount for display
    final double? paidAmount = paymentAmount != null 
        ? (paymentAmount is num ? paymentAmount.toDouble() : double.tryParse(paymentAmount.toString()))
        : null;
    
    // View button should be enabled if POD exists OR confirmation exists
    final canView = hasPOD || isConfirmed;
    
    // TEMPORARY: Confirm button is always enabled for testing
    // Original logic (commented out for restoration):
    // Confirm button should be enabled if:
    // Case 1: Not confirmed yet - need delivery done AND POD exists
    // Case 2: Confirmed but payment not done - always enable (for payment release)
    // Case 3: Confirmed and payment done - disable
    // final canConfirm = isDeliveryDone && 
    //                   (
    //                     // Not confirmed: need POD
    //                     (!isConfirmed && hasPOD) ||
    //                     // Confirmed but payment not done: always enable for payment release
    //                     (isConfirmed && !isPaymentDone)
    //                   );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proof of Delivery (POD) & Supporting Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        
        // Payment Amount Display (if confirmed)
        if (isConfirmed) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPaymentDone ? green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPaymentDone ? green : Colors.orange,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPaymentDone 
                      ? 'Payment Released' 
                      : (paidAmount != null ? 'Payment Pending' : 'No Payment Set'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPaymentDone ? green : Colors.orange,
                  ),
                ),
                Text(
                  paidAmount != null 
                      ? '\$${paidAmount.toStringAsFixed(2)}'
                      : 'N/A',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPaymentDone ? green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        Row(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ElevatedButton(
                    onPressed: canView
                        ? () => _showDeliveryStatusDetails(context, load)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canView ? blue : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: canView ? 4 : 0,
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasUnreadPOD && !isConfirmed)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showDeliveryConfirmationDialog(context, load),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  isConfirmed && !isPaymentDone 
                      ? 'Release Payment' 
                      : (isConfirmed ? 'Confirmed' : 'Confirm'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _showDeliveryStatusDetails(BuildContext context, Map<String, dynamic> load) {
    // Check POD from both load document and delivery confirmation document
    final podUrlFromLoad = load['podUrl'] as String?;
    final podUrlFromConfirmation = _deliveryConfirmationData?['podUrl'] as String?;
    final podUrl = podUrlFromConfirmation ?? podUrlFromLoad;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailsPage(
          load: load,
          deliveryConfirmationData: _deliveryConfirmationData,
          podUrl: podUrl,
        ),
      ),
    );
  }
  
  // Keep _buildInfoRow method for backward compatibility if used elsewhere
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: green, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _showDeliveryConfirmationDialog(BuildContext context, Map<String, dynamic> load) {
    // Check if payment needs to be released
    // Payment release is needed if confirmation exists but paymentAmount is null OR paymentReleased is false/null
    final confirmationData = _deliveryConfirmationData;
    final paymentAmount = confirmationData?['paymentAmount'];
    final paymentReleased = confirmationData?['paymentReleased'] == true || 
                           confirmationData?['paymentReleased'] == 1;
    
    // Payment is done only if both paymentAmount exists AND paymentReleased is true
    // If paymentAmount is null, payment hasn't been done
    final isPaymentDone = paymentAmount != null && paymentReleased == true;
    final isPaymentRelease = confirmationData != null && !isPaymentDone;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeliveryConfirmationDialog(
        load: load,
        isPaymentRelease: isPaymentRelease,
        existingConfirmation: _deliveryConfirmationData,
        onConfirm: (completionStatus, reason, notes, image, paymentAmount) async {
          await _confirmDelivery(load, completionStatus, reason, notes, image, paymentAmount);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
  
  Future<void> _confirmDelivery(
    Map<String, dynamic> load,
    String completionStatus,
    String? reason,
    String? notes,
    File? image,
    double? paymentAmount,
  ) async {
    try {
      // Get load ID - try multiple possible fields
      final loadId = load['id']?.toString() ?? 
                     load['loadId']?.toString() ??
                     load['documentId']?.toString();
      
      // Get shipper UID - try multiple possible fields
      final shipperUid = load['shipperUid']?.toString() ??
                        load['shipperId']?.toString() ??
                        FirebaseAuth.instance.currentUser?.uid;
      
      // Get carrier ID from bookedByCarrierId
      final carrierId = load['bookedByCarrierId']?.toString();
      
      if (loadId == null || loadId.isEmpty) {
        throw Exception('Missing required load information: loadId');
      }
      
      if (shipperUid == null || shipperUid.isEmpty) {
        throw Exception('Missing required load information: shipperUid');
      }
      
      if (carrierId == null || carrierId.isEmpty) {
        throw Exception('Missing required load information: bookedByCarrierId');
      }
      
      // Upload image if provided
      String? imageUrl;
      if (image != null) {
        try {
          final ref = FirebaseStorage.instance.ref().child(
            'loads/$loadId/delivery_confirmation_${DateTime.now().millisecondsSinceEpoch}.jpg'
          );
          final uploadTask = ref.putFile(image);
          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          print('Error uploading image: $e');
        }
      }
      
      // Check if this is an update to existing confirmation (payment release)
      final existingConfirmation = _deliveryConfirmationData;
      final isPaymentRelease = existingConfirmation != null && paymentAmount != null;
      
      // Process payment FIRST - must succeed before saving confirmation
      // Only process payment if there's an amount and it's a payment release
      if (paymentAmount != null && paymentAmount > 0 && isPaymentRelease) {
        try {
          await _releasePaymentToCarrier(
            carrierId: carrierId,
            loadId: loadId,
            amount: paymentAmount,
            completionStatus: completionStatus,
          );
        } catch (e) {
          print('Error releasing payment: $e');
          // Payment release failed - block confirmation
          if (mounted) {
            final errorMessage = e.toString();
            String userMessage;
            if (errorMessage.contains('connected account')) {
              userMessage = 'Cannot confirm delivery: Payment could not be transferred to carrier because they do not have a Stripe account set up. Please contact the carrier to set up their payment account.';
            } else if (errorMessage.contains('payment method') || 
                       errorMessage.contains('does not have a payment method')) {
              userMessage = 'Cannot confirm delivery: Payment could not be processed because no payment method is set up. Please go to your account settings and add a payment method, then try again.';
            } else {
              userMessage = 'Cannot confirm delivery: Payment processing failed. ${e.toString()}';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 8),
              ),
            );
          }
          // Throw error to prevent confirmation from completing
          throw Exception('Payment processing failed: ${e.toString()}');
        }
      }
      
      // Only save/update confirmation if payment succeeded (or no payment required)
      if (isPaymentRelease) {
        // Update existing confirmation to mark payment as released
        final confirmationQuery = await FirebaseFirestore.instance
            .collection('delivery_confirmations')
            .where('loadId', isEqualTo: loadId)
            .limit(1)
            .get();
        
        if (confirmationQuery.docs.isNotEmpty) {
          await confirmationQuery.docs.first.reference.update({
            'paymentReleased': true,
            'paymentReleasedAt': Timestamp.now(),
            'paymentAmount': paymentAmount,
          });
        }
      } else {
        // Create new confirmation
        final confirmationData = {
          'loadId': loadId,
          'shipperUid': shipperUid,
          'carrierUid': carrierId,
          'completionStatus': completionStatus,
          'reason': reason,
          'notes': notes,
          'imageUrl': imageUrl,
          'paymentAmount': paymentAmount,
          'paymentReleased': false, // Payment not released initially
          'confirmedAt': Timestamp.now(),
          'createdAt': Timestamp.now(),
        };
        
        await FirebaseFirestore.instance
            .collection('delivery_confirmations')
            .add(confirmationData);
        
        // Update load status only on first confirmation
        String newStatus = completionStatus == 'complete' ? 'completed' : 'in-transit';
        await FirebaseService.updateCarrierLoadStatus(
          loadId: loadId,
          status: newStatus,
          carrierUid: carrierId,
        );
      }
      
      // Reload delivery confirmation data
      await _loadDeliveryConfirmationData(loadId);
      
      if (mounted) {
        String message;
        if (existingConfirmation != null && paymentAmount != null) {
          message = 'Payment of \$${paymentAmount.toStringAsFixed(2)} released successfully';
        } else {
          message = 'Delivery confirmed as ${completionStatus == 'complete' ? 'Complete' : completionStatus == 'partial' ? 'Partially Complete' : 'Failed'}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: green,
          ),
        );
      }
    } catch (e) {
      print('Error confirming delivery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming delivery: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _releasePaymentToCarrier({
    required String carrierId,
    required String loadId,
    required double amount,
    required String completionStatus,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }
      
      // Get carrier's Stripe account ID from Firebase
      final carrierDoc = await FirebaseFirestore.instance
          .collection('carriers')
          .doc(carrierId)
          .get();
      
      if (!carrierDoc.exists) {
        throw Exception('Carrier not found');
      }
      
      final carrierData = carrierDoc.data();
      final carrierStripeAccountId = carrierData?['stripeAccountId'] as String?;
      final carrierStripeCustomerId = carrierData?['stripeCustomerId'] as String?;
      
      if (carrierStripeAccountId == null && carrierStripeCustomerId == null) {
        throw Exception('Carrier does not have a Stripe account set up');
      }
      
      // Get shipper's payment method
      final shipperDoc = await FirebaseFirestore.instance
          .collection('shippers')
          .doc(currentUser.uid)
          .get();
      
      if (!shipperDoc.exists) {
        throw Exception('Shipper not found');
      }
      
      final shipperData = shipperDoc.data();
      var shipperStripeCustomerId = shipperData?['stripeCustomerId'] as String?;
      final shipperPaymentMethodId = shipperData?['defaultPaymentMethodId'] as String?;
      
      // If shipper doesn't have stripeCustomerId, try to get/create it via setup intent
      if (shipperStripeCustomerId == null || shipperStripeCustomerId.isEmpty) {
        try {
          // Call createSetupIntent to get or create Stripe customer
          final idToken = await currentUser.getIdToken(true);
          if (idToken != null) {
            const projectId = 're-miles-dfm';
            const region = 'northamerica-northeast1';
            final setupIntentUrl = 'https://$region-$projectId.cloudfunctions.net/createSetupIntent';
            
            final setupResponse = await http.post(
              Uri.parse(setupIntentUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode({'data': {}}),
            ).timeout(const Duration(seconds: 15));
            
            if (setupResponse.statusCode == 200) {
              // Setup intent created - Stripe customer should now exist
              // Reload shipper doc to get the stripeCustomerId
              final updatedShipperDoc = await FirebaseFirestore.instance
                  .collection('shippers')
                  .doc(currentUser.uid)
                  .get();
              if (updatedShipperDoc.exists) {
                final updatedData = updatedShipperDoc.data();
                shipperStripeCustomerId = updatedData?['stripeCustomerId'] as String?;
              }
            }
          }
        } catch (e) {
          print('Error creating/getting Stripe customer: $e');
          // Continue anyway - backend will handle it
        }
      }
      
      final idToken = await currentUser.getIdToken(true);
      if (idToken == null) {
        throw Exception('Failed to obtain authentication token');
      }
      
      // Call Firebase Cloud Function to transfer payment
      // Note: Backend will handle getting stripeCustomerId if not provided
      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl = 'https://$region-$projectId.cloudfunctions.net/transferPaymentToCarrier';
      
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {
            'carrierId': carrierId,
            'carrierStripeAccountId': carrierStripeAccountId,
            'shipperId': currentUser.uid,
            'shipperStripeCustomerId': shipperStripeCustomerId, // Can be null - backend will handle
            'shipperPaymentMethodId': shipperPaymentMethodId,
            'loadId': loadId,
            'amount': (amount * 100).toInt(), // Convert to cents
            'currency': 'usd',
            'completionStatus': completionStatus,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Payment transfer timed out');
        },
      );
      
      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error']?['message'] ?? 'Payment transfer failed');
      }
      
      final responseData = jsonDecode(response.body);
      final result = responseData['result'];
      
      // Check if transfer was successful
      if (result?['success'] == true) {
        // Transfer successful
        final transferId = result['transferId'];
        
        // Store transfer record in Firestore
        await FirebaseFirestore.instance.collection('transfers').add({
          'carrierId': carrierId,
          'shipperId': currentUser.uid,
          'loadId': loadId,
          'amount': amount,
          'amountInCents': (amount * 100).toInt(),
          'currency': 'usd',
          'completionStatus': completionStatus,
          'stripeTransferId': transferId,
          'status': 'completed',
          'createdAt': Timestamp.now(),
        });
        
        // Update shipper's default payment method if it was used
        if (shipperPaymentMethodId != null) {
          await FirebaseFirestore.instance
              .collection('shippers')
              .doc(currentUser.uid)
              .update({
            'defaultPaymentMethodId': shipperPaymentMethodId,
            'lastPaymentMethodUpdate': Timestamp.now(),
          });
        }
        
        print('Payment of \$${amount.toStringAsFixed(2)} successfully transferred to carrier');
      } else if (result?['warning'] == true) {
        // Payment was charged but transfer failed - payment was refunded
        final message = result['message'] ?? 'Payment transfer failed. Payment has been refunded.';
        throw Exception(message);
      } else {
        // Other error
        throw Exception(result?['message'] ?? responseData['error']?['message'] ?? 'Payment transfer failed');
      }
    } catch (e) {
      print('Error in payment transfer: $e');
      rethrow;
    }
  }
  
  Future<void> _loadDeliveryConfirmationData(String? loadId) async {
    if (loadId == null) {
      if (mounted) {
        setState(() {
          _deliveryConfirmationData = null;
        });
      }
      return;
    }
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('delivery_confirmations')
          .where('loadId', isEqualTo: loadId)
          .limit(1)
          .get();
      
      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _deliveryConfirmationData = querySnapshot.docs.first.data();
          } else {
            _deliveryConfirmationData = null;
          }
        });
      }
    } catch (e) {
      print('Error loading delivery confirmation: $e');
      if (mounted) {
        setState(() {
          _deliveryConfirmationData = null;
        });
      }
    }
  }

  String _formatDate(dynamic dateValue, {bool includeTime = false}) {
    if (dateValue == null) return 'N/A';
    
    try {
      DateTime date;
      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'N/A';
      }
      
      if (includeTime) {
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDeliveryWindow(Map<String, dynamic> load) {
    // Try new DateTime fields first
    if (load['deliveryWindowStart'] != null && load['deliveryWindowEnd'] != null) {
      final startDate = _formatDate(load['deliveryWindowStart'], includeTime: true);
      final endDate = _formatDate(load['deliveryWindowEnd'], includeTime: true);
      if (startDate == endDate) {
        return startDate;
      }
      return '$startDate - $endDate';
    }
    
    // Fallback to old string field
    if (load['deliveryWindow'] != null) {
      return _formatDate(load['deliveryWindow'], includeTime: true);
    }
    
    return 'N/A';
  }

  void _viewDocument(BuildContext context, String? documentUrl) async {
    if (documentUrl == null || documentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Check if it's an image (common image extensions)
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
      final isImage = imageExtensions.any((ext) => documentUrl.toLowerCase().contains(ext));

      if (isImage) {
        // Navigate to full-screen image viewer
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'Document',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: PhotoView(
                imageProvider: NetworkImage(documentUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                initialScale: PhotoViewComputedScale.contained,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load document',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, event) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      } else {
        // For non-image documents, open in browser or external app
        final uri = Uri.parse(documentUrl);
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open document'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _DeliveryConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> load;
  final bool isPaymentRelease;
  final Map<String, dynamic>? existingConfirmation;
  final Function(String, String?, String?, File?, double?) onConfirm;

  const _DeliveryConfirmationDialog({
    required this.load,
    this.isPaymentRelease = false,
    this.existingConfirmation,
    required this.onConfirm,
  });

  @override
  State<_DeliveryConfirmationDialog> createState() => _DeliveryConfirmationDialogState();
}

class _DeliveryConfirmationDialogState extends State<_DeliveryConfirmationDialog> {
  static const Color green = Color(0xFF2E9340);
  static const Color blue = Color(0xFF2265A6);
  
  String? _selectedStatus; // 'complete', 'partial', 'failure'
  String? _selectedReason;
  bool _showCustomReason = false;
  String _customReason = '';
  File? _selectedImage;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  
  final List<String> _partialReasons = [
    'Some items missing',
    'Damaged items',
    'Quantity mismatch',
    'Wrong items received',
    'Partial delivery accepted by receiver',
    'Other',
  ];
  
  final List<String> _failureReasons = [
    'Delivery refused',
    'Address incorrect',
    'Recipient not available',
    'Damaged beyond repair',
    'Wrong delivery location',
    'Other',
  ];
  
  @override
  void dispose() {
    _notesController.dispose();
    _paymentController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  double? _getPaymentAmount() {
    final quoteBudget = widget.load['quoteBudget'];
    double? totalAmount;
    
    if (quoteBudget is num) {
      totalAmount = quoteBudget.toDouble();
    } else if (quoteBudget != null) {
      totalAmount = double.tryParse(quoteBudget.toString());
    }
    
    if (totalAmount == null) return null;
    
    if (_selectedStatus == 'complete') {
      return totalAmount; // Full payment
    } else if (_selectedStatus == 'partial') {
      final customAmount = double.tryParse(_paymentController.text);
      if (customAmount != null && customAmount > totalAmount / 2 && customAmount <= totalAmount) {
        return customAmount;
      }
      return totalAmount / 2; // Default to half
    }
    return 0.0; // No payment for failure
  }
  
  bool _canSubmit() {
    // For payment release, validate payment amount based on completion status
    if (widget.isPaymentRelease) {
      final paymentText = _paymentController.text.trim();
      if (paymentText.isEmpty) return false;
      final amount = double.tryParse(paymentText);
      if (amount == null || amount <= 0) return false;
      
      final quoteBudget = widget.load['quoteBudget'];
      double? totalAmount;
      if (quoteBudget is num) {
        totalAmount = quoteBudget.toDouble();
      } else if (quoteBudget != null) {
        totalAmount = double.tryParse(quoteBudget.toString());
      }
      
      if (totalAmount == null) return false;
      
      final completionStatus = widget.existingConfirmation?['completionStatus']?.toString().toLowerCase() ?? 'complete';
      
      // Complete orders must have full payment
      if (completionStatus == 'complete') {
        return amount == totalAmount;
      }
      
      // Partial orders must have more than half
      if (completionStatus == 'partial') {
        return amount > totalAmount / 2 && amount <= totalAmount;
      }
      
      return false;
    }
    
    // For new confirmation
    if (_selectedStatus == null) return false;
    if (_selectedStatus == 'complete') return true;
    if (_selectedStatus == 'partial' || _selectedStatus == 'failure') {
      if (_selectedReason == null) return false;
      if (_showCustomReason && _customReason.trim().isEmpty) return false;
      return true;
    }
    return false;
  }
  
  Future<void> _handleSubmit() async {
    if (!_canSubmit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      String completionStatus;
      String? reason;
      String? notes;
      double? paymentAmount;
      
      if (widget.isPaymentRelease) {
        // For payment release, use existing confirmation data
        completionStatus = widget.existingConfirmation!['completionStatus'] ?? 'complete';
        reason = widget.existingConfirmation!['reason'];
        notes = widget.existingConfirmation!['notes'];
        final paymentText = _paymentController.text.trim();
        paymentAmount = double.tryParse(paymentText);
      } else {
        // For new confirmation
        completionStatus = _selectedStatus!;
        reason = _showCustomReason ? _customReason.trim() : _selectedReason;
        notes = _notesController.text.trim();
        paymentAmount = _getPaymentAmount();
      }
      
      await widget.onConfirm(
        completionStatus,
        reason,
        notes?.isNotEmpty == true ? notes : null,
        _selectedImage,
        paymentAmount,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final quoteBudget = widget.load['quoteBudget'];
    double? totalAmount;
    if (quoteBudget is num) {
      totalAmount = quoteBudget.toDouble();
    } else if (quoteBudget != null) {
      totalAmount = double.tryParse(quoteBudget.toString());
    }
    
    // Get completion status for payment release
    final completionStatus = widget.isPaymentRelease && widget.existingConfirmation != null
        ? widget.existingConfirmation!['completionStatus']?.toString().toLowerCase() ?? 'complete'
        : (_selectedStatus ?? 'complete');
    
    // If this is payment release, pre-fill payment amount based on completion status
    if (widget.isPaymentRelease && widget.existingConfirmation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_paymentController.text.isEmpty) {
          final existingPayment = widget.existingConfirmation!['paymentAmount'];
          if (existingPayment != null) {
            _paymentController.text = (existingPayment is num 
                ? existingPayment.toDouble() 
                : double.tryParse(existingPayment.toString()) ?? 0.0).toStringAsFixed(2);
          } else if (totalAmount != null) {
            // Pre-fill based on completion status
            if (completionStatus == 'complete') {
              _paymentController.text = totalAmount.toStringAsFixed(2);
            } else if (completionStatus == 'partial') {
              _paymentController.text = (totalAmount / 2).toStringAsFixed(2);
            }
          }
        }
      });
    }
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 1,
          maxHeight: MediaQuery.of(context).size.height * 1,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isPaymentRelease 
                      ? [green, green.withOpacity(0.8)]
                      : [blue, blue.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isPaymentRelease ? 'Release Payment' : 'Confirm Delivery',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.isPaymentRelease && totalAmount != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Total Amount: \$${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show existing confirmation info if payment release
                    if (widget.isPaymentRelease && widget.existingConfirmation != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _getStatusColor(completionStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getStatusColor(completionStatus),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              completionStatus == 'complete'
                                  ? Icons.check_circle
                                  : completionStatus == 'partial'
                                      ? Icons.warning_amber_rounded
                                      : Icons.cancel,
                              color: _getStatusColor(completionStatus),
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Status',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    completionStatus == 'complete'
                                        ? 'Complete'
                                        : completionStatus == 'partial'
                                            ? 'Partially Complete'
                                            : 'Failed',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(completionStatus),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
              
              // Status Selection (only show if not payment release)
              if (!widget.isPaymentRelease) ...[
                const Text(
                  'Delivery Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusOption(
                        label: 'Complete',
                        value: 'complete',
                        icon: Icons.check_circle,
                        color: green,
                      ),
                    ),
                    // const SizedBox(width: 12),
                    // Expanded(
                    //   child: _buildStatusOption(
                    //     label: 'Partial',
                    //     value: 'partial',
                    //     icon: Icons.warning_amber_rounded,
                    //     color: Colors.orange,
                    //   ),
                    // ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatusOption(
                        label: 'Failure',
                        value: 'failure',
                        icon: Icons.cancel,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              
                    // Payment Amount Section
                    if (widget.isPaymentRelease || _selectedStatus == 'complete' || _selectedStatus == 'partial') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.payment,
                                  color: green,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Payment Amount',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            if (widget.isPaymentRelease) ...[
                              // Payment Release UI
                              _buildPaymentReleaseSection(totalAmount, completionStatus),
                            ] else if (_selectedStatus == 'complete') ...[
                              // Complete - Full Payment
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: green, width: 2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Full Payment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Complete delivery',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      totalAmount != null ? '\$${totalAmount.toStringAsFixed(2)}' : 'N/A',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (_selectedStatus == 'partial') ...[
                              // Partial - More than half payment
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange, width: 2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Default: Half Payment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Partial delivery',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      totalAmount != null ? '\$${(totalAmount / 2).toStringAsFixed(2)}' : 'N/A',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Or enter custom amount (more than half):',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _paymentController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        hintText: totalAmount != null 
                                            ? 'Min: \$${(totalAmount / 2).toStringAsFixed(2)}'
                                            : 'Enter amount',
                                        prefixText: '\$',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
              
              // Reason Dropdown (for partial and failure, not for payment release)
              if (!widget.isPaymentRelease && (_selectedStatus == 'partial' || _selectedStatus == 'failure')) ...[
                Text(
                  'Reason${_selectedStatus == 'partial' ? ' for Partial Delivery' : ' for Failure'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text('Select a reason'),
                    items: (_selectedStatus == 'partial' ? _partialReasons : _failureReasons)
                        .map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                        _showCustomReason = value == 'Other';
                        if (!_showCustomReason) {
                          _customReason = '';
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Custom Reason Text Field
                if (_showCustomReason) ...[
                  SizedBox(
                    width: double.infinity,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Please specify the reason',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        _customReason = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ],
                
                // Notes Field
                const Text(
                  'Notes (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Add any additional notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                
                // Image Upload
                const Text(
                  'Attach Image (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: _selectedImage != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _selectedImage!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add image',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
          ]),
              ),
            ),
            
            // Submit Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || !_canSubmit() ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isPaymentRelease ? Icons.payment : Icons.check_circle,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isPaymentRelease ? 'Release Payment' : 'Confirm Delivery',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'complete':
        return green;
      case 'partial':
        return Colors.orange;
      case 'failure':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildPaymentReleaseSection(double? totalAmount, String completionStatus) {
    if (totalAmount == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'Total amount not available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    final minAmount = completionStatus == 'complete' 
        ? totalAmount 
        : (totalAmount / 2);
    final maxAmount = totalAmount;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getStatusColor(completionStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(completionStatus),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      completionStatus == 'complete' 
                          ? 'Full Payment Required'
                          : 'Partial Payment (More than half)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(completionStatus),
                      ),
                    ),
                  ),
                  Text(
                    completionStatus == 'complete'
                        ? '\$${totalAmount.toStringAsFixed(2)}'
                        : '\$${minAmount.toStringAsFixed(2)} - \$${maxAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(completionStatus),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                completionStatus == 'complete'
                    ? 'Order is complete. Release full payment to carrier.'
                    : 'Order is partially complete. Release more than half of the payment.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Payment input
        TextField(
          controller: _paymentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Payment Amount',
            hintText: completionStatus == 'complete'
                ? '\$${totalAmount.toStringAsFixed(2)}'
                : 'Min: \$${minAmount.toStringAsFixed(2)}',
            prefixText: '\$',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        
        // Validation message
        if (_paymentController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final amount = double.tryParse(_paymentController.text);
              if (amount == null) {
                return Text(
                  'Please enter a valid amount',
                  style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                );
              }
              if (completionStatus == 'complete' && amount != totalAmount) {
                return Text(
                  'Complete orders require full payment of \$${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
                );
              }
              if (completionStatus == 'partial') {
                if (amount <= minAmount) {
                  return Text(
                    'Partial orders require more than \$${minAmount.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                  );
                }
                if (amount > maxAmount) {
                  return Text(
                    'Amount cannot exceed \$${maxAmount.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                  );
                }
              }
              return Text(
                'Amount is valid',
                style: TextStyle(color: green, fontSize: 12),
              );
            },
          ),
        ],
      ],
    );
  }
  
  Widget _buildStatusOption({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = value;
          if (value == 'complete') {
            _selectedReason = null;
            _showCustomReason = false;
            _customReason = '';
            _notesController.clear();
            _selectedImage = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.green.withOpacity(0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
      ),
    );
  }
}

