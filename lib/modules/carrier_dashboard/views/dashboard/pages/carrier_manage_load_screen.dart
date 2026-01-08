import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:remiles/core/theme/colors.dart';
import 'package:signature/signature.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:remiles/modules/carrier_dashboard/views/common/widgets/custom_progress_bar.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:remiles/providers/auth_provider.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/models/load_model.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/support.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/user_profile_dialog.dart';
import 'package:remiles/models/user_model.dart';
import 'package:remiles/core/constants/app_constants.dart';

class CarrierManageLoadScreen extends StatefulWidget {
  final String? initialLoadId;

  const CarrierManageLoadScreen({super.key, this.initialLoadId});

  @override
  State<CarrierManageLoadScreen> createState() =>
      _CarrierManageLoadScreenState();
}

class _CarrierManageLoadScreenState extends State<CarrierManageLoadScreen> {
  // Colors chosen to visually match the screenshot.
  static const Color green = Color(0xFF2E9340);
  static const Color blue = Color(0xFF2265A6);

  // Map controller
  GoogleMapController? _mapController;

  // Load data
  List<LoadModel> _bookedLoads = [];
  LoadModel? _selectedLoad;
  bool _isLoadingLoads = true;

  // Location data (will be populated from selected load)
  String _shipperName = "";
  String _shipperPhone = "";
  String _pickupAddress = "";
  String _deliveryAddress = "";
  bool _isLoadingShipperInfo = false;
  bool _isLoadingPickupAddress = false;
  bool _isLoadingDeliveryAddress = false;

  // Coordinates
  LatLng? _shipperLocation;
  LatLng? _pickupLocation;
  LatLng? _deliveryLocation;
  LatLng? _currentLocation;

  // Route data
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  List<LatLng> _routePoints = [];

  // Active location (for highlighting)
  String? _activeLocation; // 'shipper', 'pickup', 'delivery'

  // Progress calculation
  double _progress = 0.75; // 0.0 to 1.0

  // Loading state
  bool _isLoadingMap = true;
  String? _errorMessage;

  // Pickup confirmation data
  Map<String, dynamic>? _pickupConfirmationData;

  // Delivery confirmation data
  Map<String, dynamic>? _deliveryConfirmationData;

  // Escrow payment data
  Map<String, dynamic>? _escrowPaymentData;

  // Description read more state
  bool _isDescriptionExpanded = false;

  // Refresh state
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Load booked loads first
    _loadBookedLoads();
  }

  Future<void> _loadBookedLoads() async {
    try {
      // Log analytics event
      await FirebaseService.logEvent(
        'load_booked_loads_started',
        parameters: {'screen': 'marketplace'},
      );

      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier == null) {
        await FirebaseService.recordError(
          Exception('Carrier not found'),
          StackTrace.current,
          reason: 'Carrier user is null in marketplace screen',
        );
        setState(() {
          _isLoadingLoads = false;
          _errorMessage = 'Carrier not found';
        });
        return;
      }

      final result = await FirebaseService.getCarrierBookedLoads(
        carrierUid: carrier.uid,
        status: 'all', // Get all booked loads regardless of status
      );

      if (mounted) {
        // Filter to ensure only loads booked by this carrier are shown
        final allLoads = result['loads'] as List<LoadModel>? ?? [];
        final filteredLoads = allLoads
            .where((load) => load.bookedByCarrierId == carrier.uid)
            .toList();

        // Log analytics
        await FirebaseService.logEvent(
          'loads_loaded',
          parameters: {
            'screen': 'marketplace',
            'total_loads': filteredLoads.length,
          },
        );

        setState(() {
          _bookedLoads = filteredLoads;
          _isLoadingLoads = false;

          // Select load based on initialLoadId if provided, otherwise select first load
          if (_bookedLoads.isNotEmpty) {
            if (widget.initialLoadId != null) {
              // Try to find the load with the specified ID
              final foundLoad = _bookedLoads.firstWhere(
                (load) => load.id == widget.initialLoadId,
                orElse: () => _bookedLoads.first,
              );
              _selectedLoad = foundLoad;
            } else {
              _selectedLoad = _bookedLoads.first;
            }
            _updateLoadData();
          } else {
            _errorMessage = 'No booked loads found';
            _isLoadingMap = false; // Stop map loading when no loads available
          }
        });
      }
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      await FirebaseService.log('Error loading booked loads: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to load booked loads in marketplace screen',
      );

      await FirebaseService.logEvent(
        'loads_load_error',
        parameters: {'screen': 'marketplace', 'error': e.toString()},
      );

      if (mounted) {
        setState(() {
          _isLoadingLoads = false;
          _errorMessage = 'Failed to load loads: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _updateLoadData() async {
    if (_selectedLoad == null) return;

    final load = _selectedLoad!;

    // Reset map state first and update location data
    setState(() {
      // Update location data immediately
      _shipperName = load.shipperName;
      _pickupAddress =
          "${load.originAddress}, ${load.originCity}, ${load.originState}";
      _deliveryAddress =
          "${load.destinationAddress}, ${load.destinationCity}, ${load.destinationState}";

      // Reset map state
      _isLoadingMap = true;
      _errorMessage = null;
      _pickupLocation = null;
      _deliveryLocation = null;
      _shipperLocation = null;
      _currentLocation = null;
      _markers = {};
      _polylines = {};
      _routePoints = [];
      _activeLocation = null;
      _shipperPhone = ""; // Reset phone while fetching
      _pickupConfirmationData = null; // Reset pickup confirmation
      _deliveryConfirmationData = null; // Reset delivery confirmation
      _escrowPaymentData = null; // Reset escrow payment

      // Set loading states
      _isLoadingShipperInfo = true;
      // Addresses come directly from load data, so they're immediately available (not loading)
      _isLoadingPickupAddress = false;
      _isLoadingDeliveryAddress = false;
    });

    // Load pickup and delivery confirmation data
    _loadPickupConfirmationData();
    _loadDeliveryConfirmationData();
    // Load escrow payment data
    _loadEscrowPaymentData(load.id);

    // Fetch shipper phone number
    try {
      final shipper = await FirebaseService.getShipper(load.shipperUid);
      if (mounted) {
        setState(() {
          if (shipper != null &&
              shipper.phoneNumber != null &&
              shipper.phoneNumber!.isNotEmpty) {
            _shipperPhone = shipper.phoneNumber!;
          } else {
            _shipperPhone = "";
          }
          _isLoadingShipperInfo = false; // Mark as loaded
        });
      }
    } catch (e) {
      print('Error fetching shipper phone: $e');
      if (mounted) {
        setState(() {
          _shipperPhone = "";
          _isLoadingShipperInfo = false; // Mark as loaded even on error
        });
      }
    }

    // Initialize map with new load data
    _initializeMap();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Store the currently selected load ID before refresh
      final selectedLoadId = _selectedLoad?.id;
      
      // Reload booked loads
      await _loadBookedLoads();
      
      // If a load was selected, try to find it in the updated list and reload its data
      if (selectedLoadId != null) {
        try {
          final updatedLoad = _bookedLoads.firstWhere(
            (load) => load.id == selectedLoadId,
          );
          
          setState(() {
            _selectedLoad = updatedLoad;
          });
          
          // Reload all data for the selected load using the existing method
          await _updateLoadData();
        } catch (e) {
          // Load no longer exists in the list, clear selection
          if (mounted) {
            setState(() {
              _selectedLoad = null;
            });
          }
        }
      }
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadPickupConfirmationData() async {
    if (_selectedLoad == null) return;

    try {
      final querySnapshot = await FirebaseService.firestore
          .collection('pickup_confirmations')
          .where('loadId', isEqualTo: _selectedLoad!.id)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _pickupConfirmationData = querySnapshot.docs.first.data();
          } else {
            _pickupConfirmationData = null;
          }
        });
      }
    } catch (e) {
      print('Error loading pickup confirmation: $e');
      if (mounted) {
        setState(() {
          _pickupConfirmationData = null;
        });
      }
    }
  }

  Future<void> _loadDeliveryConfirmationData() async {
    if (_selectedLoad == null) return;

    try {
      final querySnapshot = await FirebaseService.firestore
          .collection('delivery_confirmations')
          .where('loadId', isEqualTo: _selectedLoad!.id)
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

  Future<void> _loadEscrowPaymentData(String loadId) async {
    try {
      final escrowPayment = await FirebaseService.getEscrowPayment(loadId);
      if (mounted) {
        setState(() {
          _escrowPaymentData = escrowPayment;
        });
      }
    } catch (e) {
      print('Error loading escrow payment: $e');
      if (mounted) {
        setState(() {
          _escrowPaymentData = null;
        });
      }
    }
  }

  Future<void> _initializeMap() async {
    try {
      // Log analytics event
      await FirebaseService.logEvent(
        'map_initialization_started',
        parameters: {
          'screen': 'marketplace',
          'load_id': _selectedLoad?.id ?? 'none',
        },
      );

      // Geocode addresses to get coordinates
      await _geocodeAddresses();

      // Only proceed if we have valid locations
      if (_pickupLocation == null || _deliveryLocation == null) {
        await FirebaseService.recordError(
          Exception('Failed to geocode addresses'),
          StackTrace.current,
          reason: 'Geocoding failed in marketplace screen',
        );
        await FirebaseService.logEvent(
          'geocoding_failed',
          parameters: {
            'screen': 'marketplace',
            'load_id': _selectedLoad?.id ?? 'none',
          },
        );

        setState(() {
          _errorMessage = 'Failed to geocode addresses';
          _isLoadingMap = false;
        });
        return;
      }

      // Get route directions
      await _getRouteDirections();

      // Calculate progress based on load status
      _calculateProgress();

      // Log successful map initialization
      await FirebaseService.logEvent(
        'map_initialized',
        parameters: {
          'screen': 'marketplace',
          'load_id': _selectedLoad?.id ?? 'none',
          'has_route': _routePoints.isNotEmpty
              ? 1
              : 0, // Convert bool to int for analytics
        },
      );

      setState(() {
        _isLoadingMap = false;
      });
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      await FirebaseService.log('Map initialization error: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to initialize map in marketplace screen',
      );

      await FirebaseService.logEvent(
        'map_initialization_error',
        parameters: {'screen': 'marketplace', 'error': e.toString()},
      );

      setState(() {
        _errorMessage = 'Failed to load map: ${e.toString()}';
        _isLoadingMap = false;
      });
    }
  }

  Future<void> _geocodeAddresses() async {
    try {
      // Geocode pickup address
      try {
        List<Location> pickupLocations = await locationFromAddress(
          _pickupAddress,
        );
        if (pickupLocations.isNotEmpty) {
          _pickupLocation = LatLng(
            pickupLocations.first.latitude,
            pickupLocations.first.longitude,
          );
        }
      } catch (e) {
        print('Pickup geocoding error: $e');
        // Use fallback coordinates
        _pickupLocation = const LatLng(46.0878, -64.7782); // Moncton, NB
      }

      // Geocode delivery address
      try {
        List<Location> deliveryLocations = await locationFromAddress(
          _deliveryAddress,
        );
        if (deliveryLocations.isNotEmpty) {
          _deliveryLocation = LatLng(
            deliveryLocations.first.latitude,
            deliveryLocations.first.longitude,
          );
        }
      } catch (e) {
        print('Delivery geocoding error: $e');
        // Use fallback coordinates
        _deliveryLocation = const LatLng(43.6532, -79.3832); // Toronto, ON
      }

      // Ensure we have at least fallback coordinates
      if (_pickupLocation == null) {
        _pickupLocation = const LatLng(46.0878, -64.7782); // Moncton, NB
      }
      if (_deliveryLocation == null) {
        _deliveryLocation = const LatLng(43.6532, -79.3832); // Toronto, ON
      }

      // For shipper location, use pickup location as default (or geocode separately)
      _shipperLocation = _pickupLocation;

      // Get current location
      await _getCurrentLocation();
    } catch (e) {
      print('Geocoding error: $e');
      // Fallback coordinates if geocoding fails
      _pickupLocation = const LatLng(46.0878, -64.7782); // Moncton, NB
      _deliveryLocation = const LatLng(43.6532, -79.3832); // Toronto, ON
      _shipperLocation = _pickupLocation;
      // Get current location even if geocoding fails
      await _getCurrentLocation();
    }
  }

  Future<void> _getRouteDirections() async {
    if (_pickupLocation == null || _deliveryLocation == null) return;

    try {
      // Use the same API key as Google Maps
      // NOTE: This API key must have "Directions API" enabled in Google Cloud Console
      // Go to: https://console.cloud.google.com/apis/library/directions-backend.googleapis.com
      // Make sure the API is enabled for your project
      const String apiKey = AppConstants.googleApiKey;

      // Use driving mode to get actual road route
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${_pickupLocation!.latitude},${_pickupLocation!.longitude}'
          '&destination=${_deliveryLocation!.latitude},${_deliveryLocation!.longitude}'
          '&mode=driving'
          '&alternatives=false'
          '&key=$apiKey';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
            final route = data['routes'][0];

            // Use detailed polyline from route steps for accurate road following
            // This gives us the actual road path, not just overview
            List<LatLng> allRoutePoints = [];

            // Get detailed polyline from each step in the route
            if (route['legs'] != null && route['legs'].isNotEmpty) {
              final legs = route['legs'] as List;
              for (var leg in legs) {
                if (leg['steps'] != null) {
                  final steps = leg['steps'] as List;
                  for (var step in steps) {
                    if (step['polyline'] != null &&
                        step['polyline']['points'] != null) {
                      final stepPolyline = step['polyline']['points'];
                      final decodedStepPoints = decodePolyline(stepPolyline);
                      final stepLatLngs = decodedStepPoints
                          .map(
                            (point) => LatLng(
                              point[0].toDouble(),
                              point[1].toDouble(),
                            ),
                          )
                          .toList();
                      allRoutePoints.addAll(stepLatLngs);
                    }
                  }
                }
              }
            }

            // If we got detailed points, use them; otherwise fall back to overview
            if (allRoutePoints.isNotEmpty) {
              _routePoints = allRoutePoints;
            } else if (route['overview_polyline'] != null &&
                route['overview_polyline']['points'] != null) {
              // Fallback to overview polyline if detailed steps aren't available
              final polyline = route['overview_polyline']['points'];
              final decodedPoints = decodePolyline(polyline);
              _routePoints = decodedPoints
                  .map(
                    (point) => LatLng(point[0].toDouble(), point[1].toDouble()),
                  )
                  .toList();
            } else {
              // Last resort: straight line
              _routePoints = [_pickupLocation!, _deliveryLocation!];
            }

            // Log successful route fetch
            await FirebaseService.logEvent(
              'route_fetched',
              parameters: {
                'screen': 'marketplace',
                'load_id': _selectedLoad?.id ?? 'none',
                'route_points_count': _routePoints.length,
                'route_type': allRoutePoints.isNotEmpty
                    ? 'detailed'
                    : 'overview',
              },
            );
          } else {
            // Log API error with detailed information
            final errorStatus = data['status']?.toString() ?? 'UNKNOWN';
            final errorMessage =
                data['error_message']?.toString() ?? 'No error message';

            print('Google Directions API error: $errorStatus - $errorMessage');
            await FirebaseService.log(
              'Google Directions API error: $errorStatus - $errorMessage',
            );
            await FirebaseService.logEvent(
              'route_api_error',
              parameters: {
                'screen': 'marketplace',
                'status': errorStatus,
                'error_message': errorMessage,
              },
            );

            // Show user-friendly error message for common issues
            if (errorStatus == 'REQUEST_DENIED') {
              print(
                '⚠️ Directions API is not enabled. Enable it at: https://console.cloud.google.com/apis/library/directions-backend.googleapis.com',
              );
            } else if (errorStatus == 'OVER_QUERY_LIMIT') {
              print(
                '⚠️ Directions API quota exceeded. Check billing at: https://console.cloud.google.com/billing',
              );
            }

            // Don't use straight line fallback - show error instead
            _routePoints = [];
          }
        } else {
          await FirebaseService.log(
            'Route API HTTP error: ${response.statusCode}',
          );
          _routePoints = [];
        }
      } catch (e, stackTrace) {
        // Log route fetch error
        await FirebaseService.log('Route fetch error: $e');
        await FirebaseService.recordError(
          e,
          stackTrace,
          reason: 'Failed to fetch route in marketplace screen',
        );
        _routePoints = [];
      }

      // Only create polyline if we have route points
      if (_routePoints.isNotEmpty) {
        if (mounted) {
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: _routePoints,
                color: blue,
                width: 6, // Increased width for better visibility
                patterns: [],
                geodesic: true, // Follow Earth's curvature
                jointType: JointType.round, // Smooth joints
                endCap: Cap.roundCap, // Rounded ends
                startCap: Cap.roundCap, // Rounded starts
              ),
            };
          });
        }
      } else {
        // Clear polylines if no route available
        if (mounted) {
          setState(() {
            _polylines = {};
          });
        }
      }

      // Create markers
      _createMarkers();

      // Update map bounds after route is created
      if (mounted) {
        // Use a small delay to ensure map is ready
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          _fitBoundsToMarkers();
        }
      }
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      await FirebaseService.log('Route directions error: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to get route directions in marketplace screen',
      );

      // Clear route on error
      if (mounted) {
        setState(() {
          _routePoints = [];
          _polylines = {};
        });
      }
      _createMarkers();

      // Update map bounds
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          _fitBoundsToMarkers();
        }
      }
    }
  }

  void _createMarkers() {
    _markers = {};

    if (_shipperLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('shipper'),
          position: _shipperLocation!,
          infoWindow: InfoWindow(title: 'Shipper', snippet: _shipperName),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _activeLocation == 'shipper'
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          infoWindow: InfoWindow(title: 'Pickup', snippet: _pickupAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _activeLocation == 'pickup'
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    if (_deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: _deliveryLocation!,
          infoWindow: InfoWindow(title: 'Delivery', snippet: _deliveryAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _activeLocation == 'delivery'
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    // Current location marker (if different from others)
    if (_currentLocation != null &&
        _currentLocation != _pickupLocation &&
        _currentLocation != _deliveryLocation) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
        ),
      );
    }
  }

  void _calculateProgress() {
    // Calculate progress based on load status
    if (_selectedLoad == null) {
      _progress = 0.0;
      return;
    }

    final status = _selectedLoad!.status.toLowerCase();

    // Map status to progress percentage (aligned with shipper view)
    switch (status) {
      case 'booked':
        _progress = 0.5; // Booked, 50% complete (aligned with shipper view)
        break;
      case 'in-transit':
        // If we have route points, calculate based on current location
        if (_routePoints.isNotEmpty && _currentLocation != null) {
          double totalDistance = 0.0;
          double completedDistance = 0.0;

          for (int i = 0; i < _routePoints.length - 1; i++) {
            double segmentDistance = _calculateDistance(
              _routePoints[i].latitude,
              _routePoints[i].longitude,
              _routePoints[i + 1].latitude,
              _routePoints[i + 1].longitude,
            );
            totalDistance += segmentDistance;

            double distToStart = _calculateDistance(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              _routePoints[i].latitude,
              _routePoints[i].longitude,
            );
            double distToEnd = _calculateDistance(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              _routePoints[i + 1].latitude,
              _routePoints[i + 1].longitude,
            );

            if (distToStart < segmentDistance && distToEnd < segmentDistance) {
              completedDistance += segmentDistance - distToEnd;
            } else if (distToEnd < distToStart) {
              completedDistance += segmentDistance;
            }
          }

          if (totalDistance > 0) {
            _progress = (completedDistance / totalDistance).clamp(0.2, 0.9);
          } else {
            _progress = 0.5; // Default for in-transit
          }
        } else {
          _progress = 0.5; // Default for in-transit without location data
        }
        break;
      case 'completed':
        _progress = 1.0; // Fully completed
        break;
      default:
        _progress = 0.0; // Default for other statuses
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  Future<void> _getCurrentLocation() async {
    try {
      // Log analytics event
      await FirebaseService.logEvent(
        'location_permission_requested',
        parameters: {
          'screen': 'marketplace',
          'load_id': _selectedLoad?.id ?? 'none',
        },
      );

      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await FirebaseService.log('Location services are disabled');
        await FirebaseService.recordError(
          Exception('Location services disabled'),
          StackTrace.current,
          reason: 'Location services disabled in marketplace screen',
        );

        // Log analytics
        await FirebaseService.logEvent(
          'location_service_disabled',
          parameters: {'screen': 'marketplace'},
        );

        // Use pickup location as fallback
        if (mounted) {
          setState(() {
            _currentLocation = _pickupLocation;
          });
        }
        return;
      }

      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await FirebaseService.log('Location permissions denied by user');
          await FirebaseService.recordError(
            Exception('Location permission denied'),
            StackTrace.current,
            reason: 'User denied location permission in marketplace screen',
          );

          // Log analytics
          await FirebaseService.logEvent(
            'location_permission_denied',
            parameters: {'screen': 'marketplace'},
          );

          if (mounted) {
            setState(() {
              _currentLocation = _pickupLocation;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await FirebaseService.log('Location permissions permanently denied');
        await FirebaseService.recordError(
          Exception('Location permission denied forever'),
          StackTrace.current,
          reason:
              'User permanently denied location permission in marketplace screen',
        );

        // Log analytics
        await FirebaseService.logEvent(
          'location_permission_denied_forever',
          parameters: {'screen': 'marketplace'},
        );

        if (mounted) {
          setState(() {
            _currentLocation = _pickupLocation;
          });
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Log successful location retrieval
      await FirebaseService.logEvent(
        'location_retrieved',
        parameters: {
          'screen': 'marketplace',
          'load_id': _selectedLoad?.id ?? 'none',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        },
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        // Update markers with current location
        _createMarkers();

        // Update map bounds to include current location
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            _fitBoundsToMarkers();
          }
        }
      }
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      await FirebaseService.log('Error getting current location: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to get current location in marketplace screen',
      );

      // Log analytics
      await FirebaseService.logEvent(
        'location_error',
        parameters: {'screen': 'marketplace', 'error': e.toString()},
      );

      // Use pickup location as fallback
      if (mounted) {
        setState(() {
          _currentLocation = _pickupLocation;
        });
      }
    }
  }

  Future<void> _makePhoneCall() async {
    if (_shipperPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Remove any non-digit characters except + for international numbers
      final phoneNumber = _shipperPhone.replaceAll(RegExp(r'[^\d+]'), '');

      if (phoneNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid phone number'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot make phone call. Please check if your device supports phone calls.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error making phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToChat() async {
    if (_selectedLoad == null) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to chat'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading indicator
      // if (!mounted) return;
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (dialogContext) => const Center(
      //     child: CircularProgressIndicator(),
      //   ),
      // );

      // Create or get conversation for load
      final conversationId = await FirebaseService.createLoadConversation(
        loadId: _selectedLoad!.id,
        carrierUid: user.uid,
        shipperUid: _selectedLoad!.shipperUid,
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
              otherUserId: _selectedLoad!.shipperUid,
              otherUserName: _selectedLoad!.shipperName,
              listingId: null,
              loadId: _selectedLoad!.id,
              loadPrice: _selectedLoad!.price,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusPills() {
    if (_selectedLoad == null) {
      return const SizedBox.shrink();
    }

    final status = _selectedLoad!.status.toLowerCase();

    // Check if waiting for escrow payment
    bool isWaitingForEscrow =
        (status == 'booked' || status == 'in-transit') &&
        _escrowPaymentData?['status'] != 'deposited';

    // Determine which status pills should be active based on load status
    // All pills should be grey if waiting for escrow payment
    bool enRouteActive =
        !isWaitingForEscrow && (status == 'booked' || status == 'in-transit');
    bool pickupActive =
        !isWaitingForEscrow &&
        (status == 'in-transit' || status == 'completed');
    bool inTransitActive = !isWaitingForEscrow && status == 'in-transit';
    bool deliveredActive = !isWaitingForEscrow && status == 'completed';

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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildEscrowWaitingMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade50,
            Colors.orange.shade50,
            Colors.deepOrange.shade50,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.orange.shade100.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated background shimmer effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment(-1.0, -1.0),
                  end: Alignment(1.0, 1.0),
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container with gradient and glow
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.shade400,
                        Colors.deepOrange.shade500,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade400.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Waiting for Escrow Payment',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.deepOrange.shade900,
                                letterSpacing: 0.2,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepOrange.shade800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'The shipper needs to deposit the payment into escrow before you can proceed to the pickup location. You will be notified once the payment is deposited.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.deepOrange.shade700,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Progress indicator bar
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.35,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade400,
                                      Colors.deepOrange.shade400,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.shade400.withOpacity(
                                        0.6,
                                      ),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionRow() {
    if (_selectedLoad == null) return const SizedBox.shrink();

    final description = _selectedLoad!.description.isNotEmpty
        ? _selectedLoad!.description
        : 'No description provided';
    final needsTruncation =
        description.length > 150 && description != 'No description provided';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              child: needsTruncation
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          maxLines: _isDescriptionExpanded ? null : 3,
                          overflow: _isDescriptionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDescriptionExpanded = !_isDescriptionExpanded;
                            });
                          },
                          child: Text(
                            _isDescriptionExpanded ? 'Read less' : 'Read more',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: green,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  void _viewShipperProfile() {
    if (_selectedLoad == null) return;

    showDialog(
      context: context,
      builder: (context) => UserProfileDialog(
        userId: _selectedLoad!.shipperUid,
        userName: _selectedLoad!.shipperName.isNotEmpty
            ? _selectedLoad!.shipperName
            : 'Shipper',
        userRole: UserRole.shipper,
      ),
    );
  }

  String _getConfirmationTimeText() {
    if (_pickupConfirmationData == null) return '';

    try {
      final confirmedAt = _pickupConfirmationData!['confirmedAt'];
      if (confirmedAt == null) return 'Confirmed';

      DateTime confirmationDate;
      if (confirmedAt is Timestamp) {
        confirmationDate = confirmedAt.toDate();
      } else if (confirmedAt is String) {
        confirmationDate = DateTime.parse(confirmedAt);
      } else {
        return 'Confirmed';
      }

      final now = DateTime.now();
      final difference = now.difference(confirmationDate);

      if (difference.inDays > 0) {
        return 'Confirmed ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return 'Confirmed ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return 'Confirmed ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Confirmed just now';
      }
    } catch (e) {
      return 'Confirmed';
    }
  }

  String _getDeliveryConfirmationTimeText() {
    if (_deliveryConfirmationData == null) return '';

    try {
      final confirmedAt = _deliveryConfirmationData!['confirmedAt'];
      if (confirmedAt == null) return 'Confirmed';

      DateTime confirmationDate;
      if (confirmedAt is Timestamp) {
        confirmationDate = confirmedAt.toDate();
      } else if (confirmedAt is String) {
        confirmationDate = DateTime.parse(confirmedAt);
      } else {
        return 'Confirmed';
      }

      final now = DateTime.now();
      final difference = now.difference(confirmationDate);

      if (difference.inDays > 0) {
        return 'Confirmed ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return 'Confirmed ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return 'Confirmed ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Confirmed just now';
      }
    } catch (e) {
      return 'Confirmed';
    }
  }

  void _onLocationCardTap(String locationType) {
    setState(() {
      _activeLocation = locationType;
    });

    LatLng? targetLocation;
    switch (locationType) {
      case 'shipper':
        targetLocation = _shipperLocation;
        break;
      case 'pickup':
        targetLocation = _pickupLocation;
        break;
      case 'delivery':
        targetLocation = _deliveryLocation;
        break;
    }

    if (targetLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(targetLocation, 14.0),
      );
    }

    // Recreate markers with updated active state
    _createMarkers();
    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Fit camera to show all markers including current location
    _fitBoundsToMarkers();
  }

  void _fitBoundsToMarkers() {
    // Check if widget is still mounted and controller is valid
    if (!mounted) return;

    // Store controller reference to avoid race conditions
    final controller = _mapController;
    if (controller == null) return;

    try {
      List<LatLng> allLocations = [];

      if (_pickupLocation != null) allLocations.add(_pickupLocation!);
      if (_deliveryLocation != null) allLocations.add(_deliveryLocation!);
      if (_currentLocation != null) allLocations.add(_currentLocation!);
      if (_shipperLocation != null &&
          _shipperLocation != _pickupLocation &&
          _shipperLocation != _deliveryLocation) {
        allLocations.add(_shipperLocation!);
      }

      if (allLocations.isEmpty) return;

      double minLat = allLocations
          .map((l) => l.latitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLat = allLocations
          .map((l) => l.latitude)
          .reduce((a, b) => a > b ? a : b);
      double minLng = allLocations
          .map((l) => l.longitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLng = allLocations
          .map((l) => l.longitude)
          .reduce((a, b) => a > b ? a : b);

      // Final check before using controller - must be mounted and controller must still be valid
      if (!mounted || _mapController != controller) return;

      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0, // padding
        ),
      );
    } catch (e) {
      // Silently handle if widget is disposed - don't log if not mounted
      // This is expected when widget is disposed during async operations
    }
  }

  String _getConfirmButtonText() {
    if (_selectedLoad == null) return "Confirm Load\nDelivery";

    switch (_activeLocation) {
      case 'pickup':
        // If pickup is already confirmed, show "View" instead
        if (_pickupConfirmationData != null) {
          return "View\nPickup";
        }
        return "Confirm\nPickup";
      case 'delivery':
        // If delivery is already confirmed, show "View" instead
        if (_deliveryConfirmationData != null) {
          return "View\nDelivery";
        }
        return "Confirm\nDelivery";
      case 'shipper':
      default:
        return "Confirm Load\nDelivery";
    }
  }

  bool _isConfirmButtonEnabled() {
    if (_selectedLoad == null) return false;

    final locationType = _activeLocation ?? 'delivery';

    // Pickup confirmation requires escrow payment to be deposited
    if (locationType == 'pickup') {
      // Check if escrow payment is deposited
      final escrowStatus = _escrowPaymentData?['status'] as String?;
      if (escrowStatus != 'deposited') {
        return false; // Disable pickup if escrow is not deposited
      }
      return true;
    }

    // For delivery confirmation, pickup must be confirmed first
    if (locationType == 'delivery' ||
        locationType == 'shipper' ||
        _activeLocation == null) {
      // If delivery is already confirmed, allow viewing it
      if (_deliveryConfirmationData != null) {
        return true;
      }
      // For confirming delivery, pickup must be confirmed first
      return _pickupConfirmationData != null;
    }

    return true;
  }

  Future<void> _showConfirmationDialog() async {
    if (_selectedLoad == null) return;

    final locationType = _activeLocation ?? 'delivery';
    final isPickup = locationType == 'pickup';

    // Prevent pickup if escrow payment is not deposited
    if (isPickup) {
      final escrowStatus = _escrowPaymentData?['status'] as String?;
      if (escrowStatus != 'deposited') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot proceed with pickup. Shipper must deposit escrow payment first.',
              ),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    // Prevent confirming delivery if pickup is not confirmed
    // Allow viewing already confirmed delivery even if pickup data is missing
    if (!isPickup &&
        _pickupConfirmationData == null &&
        _deliveryConfirmationData == null) {
      // Show a message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please confirm pickup before confirming delivery'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ConfirmationPage(
          loadId: _selectedLoad!.id,
          load: _selectedLoad!,
          locationType: locationType,
          isPickup: isPickup,
          onStatusUpdated: () {
            // Reload loads to get updated status
            _loadBookedLoads();
            // Reload pickup and delivery confirmation data
            _loadPickupConfirmationData();
            _loadDeliveryConfirmationData();
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _showSupportDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.support_agent, color: green, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How would you like to contact support?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Call Support Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _callSupport();
                },
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text(
                  'Call Support',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Report Issue Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _navigateToReport();
                },
                icon: const Icon(Icons.report_problem, color: Colors.white),
                label: const Text(
                  'Report Issue',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Chat Support Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _navigateToChatSupport();
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
                label: const Text(
                  'Chat Support',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callSupport() async {
    const supportPhone =
        '+1-555-123-4567'; // Replace with actual support number

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot make phone call. Please check if your device supports phone calls.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToReport() async {
    try {
      // Navigate to support screen for reporting issues
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SupportScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open report screen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToChatSupport() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to chat with support'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create or get support conversation
      final conversationId =
          await FirebaseService.createOrGetSupportConversation(user.uid);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Navigate to support chat screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(conversationId: conversationId, isSupportChat: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open support chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar without padding
            TopNavigationBar(context),

            // Rest of the content with padding + scroll
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 20,
                ),
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content doesn't scroll
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Load ID Dropdown and Support Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Load ID: ",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: 1.2,
                              ),
                            ),
                            Expanded(
                              child: _isLoadingLoads
                                  ? const Text(
                                      "Loading loads...",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : _bookedLoads.isEmpty
                                  ? const Text(
                                      "No loads available",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : DropdownButton<LoadModel>(
                                      value: _selectedLoad,
                                      isExpanded: true,
                                      underline: Container(),
                                      icon: const Icon(Icons.arrow_drop_down),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        height: 1.2,
                                      ),
                                      selectedItemBuilder:
                                          (BuildContext context) {
                                            return _bookedLoads.map<Widget>((
                                              load,
                                            ) {
                                              final shortId = load.id.length > 8
                                                  ? load.id.substring(0, 8)
                                                  : load.id;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  "#$shortId",
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              );
                                            }).toList();
                                          },
                                      items: _bookedLoads.map((load) {
                                        final shortId = load.id.length > 8
                                            ? load.id.substring(0, 8)
                                            : load.id;
                                        return DropdownMenuItem<LoadModel>(
                                          value: load,
                                          child: Text(
                                            "#$shortId",
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (LoadModel? newLoad) {
                                        if (newLoad != null) {
                                          setState(() {
                                            _selectedLoad = newLoad;
                                          });
                                          _updateLoadData();
                                        }
                                      },
                                    ),
                            ),
                            // Refresh Button (Web only)
                            if (kIsWeb) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _isRefreshing ? null : _refreshData,
                                  icon: _isRefreshing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.refresh, size: 20),
                                  label: const Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            // Support Button
                            IconButton(
                              onPressed: _showSupportDialog,
                              icon: const Icon(Icons.support_agent_rounded),
                              color: green,
                              iconSize: 28,
                              tooltip: 'Contact Support',
                            ),
                          ],
                        ),
                      ),

                      // --- Load Details Card ---
                      if (_selectedLoad != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Load Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Load ID',
                                '#${_selectedLoad!.id}',
                              ),
                              const SizedBox(height: 8),
                              // Price
                              _buildDetailRow(
                                'Price',
                                '\$${_selectedLoad!.price.toStringAsFixed(2)} CAD',
                              ),
                              const SizedBox(height: 8),
                              // Description with read more
                              _buildDescriptionRow(),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                'Pickup',
                                '${_selectedLoad!.originAddress}, ${_selectedLoad!.originCity}, ${_selectedLoad!.originState}',
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                'Pickup Time',
                                DateFormat(
                                  'MMM dd, yyyy • hh:mm a',
                                ).format(_selectedLoad!.pickupDate),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                'Delivery',
                                '${_selectedLoad!.destinationAddress}, ${_selectedLoad!.destinationCity}, ${_selectedLoad!.destinationState}',
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                'Delivery Time',
                                DateFormat(
                                  'MMM dd, yyyy • hh:mm a',
                                ).format(_selectedLoad!.deliveryDate),
                              ),
                              // Show delivery confirmation details if delivery is confirmed
                              if (_deliveryConfirmationData != null) ...[
                                const SizedBox(height: 8),
                                _buildDetailRow('Delivered', 'Yes'),
                                const SizedBox(height: 8),
                                if (_deliveryConfirmationData!['confirmedAt'] !=
                                    null) ...[
                                  _buildDetailRow(
                                    'Delivered Date',
                                    DateFormat('MMM dd, yyyy • hh:mm a').format(
                                      (_deliveryConfirmationData!['confirmedAt']
                                              as Timestamp)
                                          .toDate(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                _buildDetailRow(
                                  'Delivery Status',
                                  _deliveryConfirmationData!['completionStatus'] ==
                                          'complete'
                                      ? 'Complete'
                                      : 'Partial Success',
                                ),
                              ],
                              if (_selectedLoad!.weight > 0) ...[
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  'Weight',
                                  '${_selectedLoad!.weight} lbs',
                                ),
                              ],
                              if (_selectedLoad!.distance > 0) ...[
                                const SizedBox(height: 8),
                                _buildDetailRow(
                                  'Distance',
                                  '${_selectedLoad!.distance.toStringAsFixed(1)} miles',
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // --- Top status pills (based on load status) ---
                      _buildStatusPills(),

                      const SizedBox(height: 20),

                      // Escrow payment waiting message (only show if booked/in-transit and escrow not deposited)
                      if (_selectedLoad != null &&
                          (_selectedLoad!.status == 'booked' ||
                              _selectedLoad!.status == 'in-transit') &&
                          _escrowPaymentData?['status'] != 'deposited') ...[
                        _buildEscrowWaitingMessage(),
                        const SizedBox(height: 20),
                      ],

                      // --- Google Map with route ---
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      green,
                                    ),
                                  ),
                                )
                              : _errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : _selectedLoad == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No load selected',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : _pickupLocation != null &&
                                    _deliveryLocation != null
                              ? GoogleMap(
                                  key: ValueKey(
                                    'map_${_routePoints.length}_${_selectedLoad?.id}',
                                  ), // Force rebuild when route changes
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
                                      const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              green,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Loading route...',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Progress bar with percent on right ---
                      CustomProgressBar(value: _progress),

                      const SizedBox(height: 24),

                      // --- Shipper row ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shipper / Pickup / Delivery column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Shipper card
                                GestureDetector(
                                  onTap: () => _onLocationCardTap('shipper'),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _activeLocation == 'shipper'
                                            ? blue
                                            : green,
                                        width: _activeLocation == 'shipper'
                                            ? 3
                                            : 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (_activeLocation == 'shipper'
                                                      ? blue
                                                      : green)
                                                  .withOpacity(0.18),
                                          blurRadius: 4,
                                          spreadRadius: 0.5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Shipper",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: _activeLocation == 'shipper'
                                                ? blue
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _isLoadingShipperInfo
                                            ? Row(
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(green),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Loading shipper info...',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : _shipperName.isNotEmpty
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  GestureDetector(
                                                    onTap: _selectedLoad != null
                                                        ? _viewShipperProfile
                                                        : null,
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _shipperName,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                _selectedLoad !=
                                                                    null
                                                                ? green
                                                                : Colors.black,
                                                            decoration:
                                                                _selectedLoad !=
                                                                    null
                                                                ? TextDecoration
                                                                      .underline
                                                                : null,
                                                          ),
                                                        ),
                                                        if (_selectedLoad !=
                                                            null) ...[
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Icon(
                                                            Icons.person,
                                                            size: 16,
                                                            color: green,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  if (_shipperPhone
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _shipperPhone,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              )
                                            : Text(
                                                'No shipper info available',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade600,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Pickup card
                                GestureDetector(
                                  onTap: () => _onLocationCardTap('pickup'),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _pickupConfirmationData != null
                                          ? green.withOpacity(0.05)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _pickupConfirmationData != null
                                            ? green
                                            : (_activeLocation == 'pickup'
                                                  ? blue
                                                  : Colors.white),
                                        width: _pickupConfirmationData != null
                                            ? 2.5
                                            : (_activeLocation == 'pickup'
                                                  ? 3
                                                  : 2),
                                      ),
                                      boxShadow:
                                          _activeLocation == 'pickup' ||
                                              _pickupConfirmationData != null
                                          ? [
                                              BoxShadow(
                                                color:
                                                    (_pickupConfirmationData !=
                                                                null
                                                            ? green
                                                            : blue)
                                                        .withOpacity(0.18),
                                                blurRadius: 4,
                                                spreadRadius: 0.5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Pickup",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color:
                                                    _pickupConfirmationData !=
                                                        null
                                                    ? green
                                                    : (_activeLocation ==
                                                              'pickup'
                                                          ? blue
                                                          : Colors.black),
                                              ),
                                            ),
                                            if (_pickupConfirmationData != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: green,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Confirmed',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _isLoadingPickupAddress
                                            ? Row(
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(green),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Loading address...',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : _pickupAddress.isNotEmpty
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _pickupAddress,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  // Show confirmation timestamp if confirmed
                                                  if (_pickupConfirmationData !=
                                                      null) ...[
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 14,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          _getConfirmationTimeText(),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              )
                                            : Text(
                                                'No pickup address available',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade600,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Delivery card
                                GestureDetector(
                                  onTap: () => _onLocationCardTap('delivery'),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _deliveryConfirmationData != null
                                          ? green.withOpacity(0.05)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _deliveryConfirmationData != null
                                            ? green
                                            : (_activeLocation == 'delivery'
                                                  ? blue
                                                  : Colors.white),
                                        width: _deliveryConfirmationData != null
                                            ? 2.5
                                            : (_activeLocation == 'delivery'
                                                  ? 3
                                                  : 2),
                                      ),
                                      boxShadow:
                                          _activeLocation == 'delivery' ||
                                              _deliveryConfirmationData != null
                                          ? [
                                              BoxShadow(
                                                color:
                                                    (_deliveryConfirmationData !=
                                                                null
                                                            ? green
                                                            : blue)
                                                        .withOpacity(0.18),
                                                blurRadius: 4,
                                                spreadRadius: 0.5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Delivery",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color:
                                                    _deliveryConfirmationData !=
                                                        null
                                                    ? green
                                                    : (_activeLocation ==
                                                              'delivery'
                                                          ? blue
                                                          : Colors.black),
                                              ),
                                            ),
                                            if (_deliveryConfirmationData !=
                                                null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: green,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Confirmed',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _isLoadingDeliveryAddress
                                            ? Row(
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(green),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Loading address...',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : _deliveryAddress.isNotEmpty
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _deliveryAddress,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  // Show confirmation timestamp if confirmed
                                                  if (_deliveryConfirmationData !=
                                                      null) ...[
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 14,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          _getDeliveryConfirmationTimeText(),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              )
                                            : Text(
                                                'No delivery address available',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade600,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Call & Chat buttons
                          Column(
                            children: [
                              IconButton(
                                onPressed: _shipperPhone.isNotEmpty
                                    ? () {
                                        print(
                                          'Call button pressed. Phone: $_shipperPhone',
                                        );
                                        _makePhoneCall();
                                      }
                                    : () {
                                        print(
                                          'Call button pressed but phone is empty',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Phone number not available',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.phone_rounded),
                                color: _shipperPhone.isNotEmpty
                                    ? green
                                    : Colors.grey.shade400,
                                iconSize: 30,
                                tooltip: _shipperPhone.isNotEmpty
                                    ? 'Call $_shipperPhone'
                                    : 'Phone number not available',
                              ),
                              const SizedBox(height: 6),
                              IconButton(
                                onPressed: _selectedLoad != null
                                    ? () {
                                        print(
                                          'Message button pressed. Load ID: ${_selectedLoad!.id}',
                                        );
                                        _navigateToChat();
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                ),
                                color: _selectedLoad != null
                                    ? green
                                    : Colors.grey.shade400,
                                iconSize: 30,
                                tooltip: 'Message ${_shipperName}',
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 40), // instead of Spacer()
                      // bottom row with confirm button
                      if (_selectedLoad != null)
                        Row(
                          children: [
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _isConfirmButtonEnabled()
                                  ? () => _showConfirmationDialog()
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isConfirmButtonEnabled()
                                    ? green
                                    : Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: _isConfirmButtonEnabled() ? 8 : 0,
                                shadowColor: _isConfirmButtonEnabled()
                                    ? Colors.black45
                                    : Colors.transparent,
                              ),
                              child: Text(
                                _getConfirmButtonText(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _isConfirmButtonEnabled()
                                      ? Colors.white
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
       
      ],
    ),
      ),
    );
  }
}

/// Status pill widget with border and slight shadow to match screenshot.
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

/// Confirmation page for pickup/delivery status updates
class _ConfirmationPage extends StatefulWidget {
  final String loadId;
  final LoadModel load;
  final String locationType;
  final bool isPickup;
  final VoidCallback onStatusUpdated;

  const _ConfirmationPage({
    required this.loadId,
    required this.load,
    required this.locationType,
    required this.isPickup,
    required this.onStatusUpdated,
  });

  @override
  State<_ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<_ConfirmationPage> {
  static const Color green = Color(0xFF2E9340);
  static const Color red = const Color(0xFFEB001B);

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  String _selectedStatus = 'success'; // 'success' or 'failed'
  String? _selectedReason;
  String _customReason = '';
  bool _showCustomReason = false;
  dynamic _selectedImage;
  dynamic _podFile; // Proof of Delivery file
  dynamic _deliveryPhoto; // Delivery photo
  bool _isSubmitting = false;

  // For pickup success: 'complete' or 'partial' - MUST be explicitly selected by user
  String? _pickupCompletionStatus; // Explicitly null until user selects

  // For delivery success: 'complete' or 'partial' - MUST be explicitly selected by user
  String? _deliveryCompletionStatus; // Explicitly null until user selects

  // For delivery partial success: reason and notes
  String? _partialSuccessReason;
  String _partialSuccessCustomReason = '';
  bool _showPartialSuccessCustomReason = false;
  String _deliveryNotes = '';
  final TextEditingController _deliveryNotesController =
      TextEditingController();

  // Pickup confirmation data (will be loaded from Firestore)
  Map<String, dynamic>? _pickupConfirmationData;
  // Delivery confirmation data (will be loaded from Firestore)
  Map<String, dynamic>? _deliveryConfirmationData;
  bool _isLoadingConfirmationData = true;

  // Check if pickup is already confirmed - must have actual confirmation data
  bool get _isPickupConfirmed =>
      widget.isPickup &&
      _pickupConfirmationData != null &&
      !_isLoadingConfirmationData;

  // Check if delivery is already confirmed - must have actual confirmation data
  bool get _isDeliveryConfirmed =>
      !widget.isPickup &&
      _deliveryConfirmationData != null &&
      !_isLoadingConfirmationData;

  // Predefined reasons for pickup failures
  final List<String> _pickupFailureReasons = [
    'Address not found',
    'No one available at pickup location',
    'Incorrect address provided',
    'Access denied to pickup location',
    'Item not ready for pickup',
    'Damaged item at pickup',
    'Wrong item provided',
    'Other',
  ];

  // Predefined reasons for delivery failures
  final List<String> _deliveryFailureReasons = [
    'Address not found',
    'No one available at delivery location',
    'Incorrect address provided',
    'Access denied to delivery location',
    'Recipient not available',
    'Damaged item during transit',
    'Wrong delivery address',
    'Recipient refused delivery',
    'Item returned to sender',
    'Delivery location closed',
    'Weather conditions prevented delivery',
    'Other',
  ];

  List<String> get _failureReasons =>
      widget.isPickup ? _pickupFailureReasons : _deliveryFailureReasons;

  @override
  void initState() {
    super.initState();
    // Explicitly ensure completion status is null (not pre-selected)
    _pickupCompletionStatus = null;
    _deliveryCompletionStatus = null;
    _loadPickupConfirmationData();
    _loadDeliveryConfirmationData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _receiverNameController.dispose();
    _signatureController.dispose();
    _deliveryNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadPickupConfirmationData() async {
    if (!widget.isPickup) {
      return;
    }

    try {
      // Always check for pickup confirmation data in Firestore
      final querySnapshot = await FirebaseService.firestore
          .collection('pickup_confirmations')
          .where('loadId', isEqualTo: widget.loadId)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _pickupConfirmationData = querySnapshot.docs.first.data();
          } else {
            _pickupConfirmationData = null;
          }
          _isLoadingConfirmationData = false;
        });
      }
    } catch (e) {
      print('Error loading pickup confirmation: $e');
      if (mounted) {
        setState(() {
          _pickupConfirmationData = null;
          _isLoadingConfirmationData = false;
        });
      }
    }
  }

  Future<void> _loadDeliveryConfirmationData() async {
    if (widget.isPickup) {
      setState(() {
        _isLoadingConfirmationData = false;
      });
      return;
    }

    try {
      // Always check for delivery confirmation data in Firestore
      final querySnapshot = await FirebaseService.firestore
          .collection('delivery_confirmations')
          .where('loadId', isEqualTo: widget.loadId)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _deliveryConfirmationData = querySnapshot.docs.first.data();
          } else {
            _deliveryConfirmationData = null;
          }
          _isLoadingConfirmationData = false;
        });
      }
    } catch (e) {
      print('Error loading delivery confirmation: $e');
      if (mounted) {
        setState(() {
          _deliveryConfirmationData = null;
          _isLoadingConfirmationData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while checking for confirmation data
    if (_isLoadingConfirmationData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isPickup ? 'Confirm Pickup' : 'Confirm Delivery'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If pickup is already confirmed (has confirmation data), show confirmation details
    if (widget.isPickup && _isPickupConfirmed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pickup Confirmed'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildPickupConfirmationDetails(),
      );
    }

    // If delivery is already confirmed (has confirmation data), show confirmation details
    if (!widget.isPickup && _isDeliveryConfirmed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Delivery Confirmed'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildDeliveryConfirmationDetails(),
      );
    }

    // Otherwise show the confirmation form
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPickup ? 'Confirm Pickup' : 'Confirm Delivery'),
        leading: _isSubmitting
            ? null // Hide back button during submission
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
        automaticallyImplyLeading:
            !_isSubmitting, // Prevent back button during submission
      ),
      body: PopScope(
        canPop: !_isSubmitting, // Prevent back button during submission
        child: _buildConfirmationForm(),
      ),
    );
  }

  Widget _buildPickupConfirmationDetails() {
    final confirmationDate = _pickupConfirmationData?['confirmedAt'] != null
        ? (_pickupConfirmationData!['confirmedAt'] as Timestamp).toDate()
        : null;
    final completionStatus =
        _pickupConfirmationData?['completionStatus'] ?? 'Complete';
    final notes = _pickupConfirmationData?['notes'] ?? '';
    final imageUrl = _pickupConfirmationData?['imageUrl'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.check_circle, color: green, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Pickup Confirmed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Confirmed date/time
          if (confirmationDate != null) ...[
            _buildInfoRow(
              'Confirmed At',
              DateFormat('MMM dd, yyyy • hh:mm a').format(confirmationDate),
              Icons.access_time,
            ),
            const SizedBox(height: 16),
          ],

          // Completion status
          _buildInfoRow(
            'Status',
            completionStatus == 'complete' ? 'Complete' : 'Partial Success',
            Icons.info_outline,
          ),

          const SizedBox(height: 16),

          // Notes
          if (notes.isNotEmpty) ...[
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(notes, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 16),
          ],

          // Image
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            Text(
              'Confirmation Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryConfirmationDetails() {
    final confirmationDate = _deliveryConfirmationData?['confirmedAt'] != null
        ? (_deliveryConfirmationData!['confirmedAt'] as Timestamp).toDate()
        : null;
    final completionStatus =
        _deliveryConfirmationData?['completionStatus'] ?? 'Complete';
    final receiverName = _deliveryConfirmationData?['receiverName'] ?? '';
    final signatureUrl = _deliveryConfirmationData?['signatureUrl'] as String?;
    final podUrl = _deliveryConfirmationData?['podUrl'] as String?;
    final deliveryPhotoUrl =
        _deliveryConfirmationData?['deliveryPhotoUrl'] as String?;
    final partialSuccessReason =
        _deliveryConfirmationData?['partialSuccessReason'] as String?;
    final notes = _deliveryConfirmationData?['notes'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.check_circle, color: green, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Delivery Confirmed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Confirmed date/time
          if (confirmationDate != null) ...[
            _buildInfoRow(
              'Confirmed At',
              DateFormat('MMM dd, yyyy • hh:mm a').format(confirmationDate),
              Icons.access_time,
            ),
            const SizedBox(height: 16),
          ],

          // Completion status
          _buildInfoRow(
            'Status',
            completionStatus == 'complete' ? 'Complete' : 'Partial Success',
            Icons.info_outline,
          ),

          const SizedBox(height: 16),

          // Receiver name
          if (receiverName.isNotEmpty) ...[
            _buildInfoRow('Receiver Name', receiverName, Icons.person),
            const SizedBox(height: 16),
          ],

          // Partial success reason (if applicable)
          if (completionStatus == 'partial' &&
              partialSuccessReason != null &&
              partialSuccessReason.isNotEmpty) ...[
            Text(
              'Reason for Partial Success',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                partialSuccessReason,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          if (notes != null && notes.isNotEmpty) ...[
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(notes, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 16),
          ],

          // Signature
          if (signatureUrl != null && signatureUrl.isNotEmpty) ...[
            Text(
              'Receiver Signature',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                signatureUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Proof of Delivery (POD)
          if (podUrl != null && podUrl.isNotEmpty) ...[
            Text(
              'Proof of Delivery (POD)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                podUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Delivery Photo
          if (deliveryPhotoUrl != null && deliveryPhotoUrl.isNotEmpty) ...[
            Text(
              'Delivery Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                deliveryPhotoUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status selection (for both pickup and delivery)
          Text(
            'Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusOption(
                  label: widget.isPickup ? 'Picked Up' : 'Delivered',
                  value: 'success',
                  icon: Icons.check_circle,
                  color: green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusOption(
                  label: 'Failed',
                  value: 'failed',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Delivery confirmation form (only for delivery success)
          if (!widget.isPickup && _selectedStatus == 'success') ...[
            _buildDeliveryConfirmationForm(),
          ],

          // Delivery completion status (only for delivery success)
          if (!widget.isPickup && _selectedStatus == 'success') ...[
            Row(
              children: [
                Text(
                  'Delivery Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompletionStatusOption(
                    label: 'Complete',
                    value: 'complete',
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompletionStatusOption(
                    label: 'Partial Success',
                    value: 'partial',
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            // Show helper text if nothing selected
            if (_deliveryCompletionStatus == null) ...[
              const SizedBox(height: 8),
              Text(
                'Please select one of the options above',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Partial success reason and notes (only for partial success)
            if (_deliveryCompletionStatus == 'partial') ...[
              Text(
                'Reason for Partial Success',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _partialSuccessReason,
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
                items:
                    [
                      'Some items missing',
                      'Damaged items',
                      'Quantity mismatch',
                      'Wrong items received',
                      'Partial delivery accepted by receiver',
                      'Other',
                    ].map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(reason, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _partialSuccessReason = value;
                    _showPartialSuccessCustomReason = value == 'Other';
                    if (!_showPartialSuccessCustomReason) {
                      _partialSuccessCustomReason = '';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Custom reason text field for partial success
              if (_showPartialSuccessCustomReason) ...[
                TextField(
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
                      _partialSuccessCustomReason = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),

              // Notes field for delivery
              Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deliveryNotesController,
                decoration: InputDecoration(
                  hintText: 'Add any additional notes about the delivery...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 4,
                onChanged: (value) {
                  setState(() {
                    _deliveryNotes = value;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
          ],

          // Delivery failure reason (only for delivery failure)
          if (!widget.isPickup && _selectedStatus == 'failed') ...[
            Text(
              'Reason for Failure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
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
              items: _deliveryFailureReasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason, overflow: TextOverflow.ellipsis),
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

            const SizedBox(height: 16),

            // Custom reason text field
            if (_showCustomReason) ...[
              TextField(
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
              const SizedBox(height: 16),
            ],

            // Image attachment (optional for failures)
            Text(
              'Attach Image (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                    (_selectedImage as XFile).path,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    _selectedImage is XFile
                                        ? File((_selectedImage as XFile).path)
                                        : _selectedImage as File,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
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

          // Pickup completion status (only for pickup success)
          if (widget.isPickup && _selectedStatus == 'success') ...[
            Row(
              children: [
                Text(
                  'Pickup Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Ensure neither is pre-selected - user must explicitly choose
            Row(
              children: [
                Expanded(
                  child: _buildCompletionStatusOption(
                    label: 'Complete',
                    value: 'complete',
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompletionStatusOption(
                    label: 'Partial Success',
                    value: 'partial',
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            // Show helper text if nothing selected
            if (_pickupCompletionStatus == null) ...[
              const SizedBox(height: 8),
              Text(
                'Please select one of the options above',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Notes field
            Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add any additional notes about the pickup...',
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
            const SizedBox(height: 24),

            // Image attachment
            Text(
              'Attach Image (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                    (_selectedImage as XFile).path,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    _selectedImage is XFile
                                        ? File((_selectedImage as XFile).path)
                                        : _selectedImage as File,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
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

          // Failure reason (only show if failed and pickup)
          if (widget.isPickup && _selectedStatus == 'failed') ...[
            Text(
              'Reason for Failure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
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
              items: _failureReasons.map((reason) {
                return DropdownMenuItem(
                  value: reason,
                  child: Text(reason, overflow: TextOverflow.ellipsis),
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

            const SizedBox(height: 16),

            // Custom reason text field
            if (_showCustomReason) ...[
              TextField(
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
              const SizedBox(height: 16),
            ],

            // Image attachment (optional for failures)
            Text(
              'Attach Image (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                    (_selectedImage as XFile).path,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    _selectedImage is XFile
                                        ? File((_selectedImage as XFile).path)
                                        : _selectedImage as File,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
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

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Confirm',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : Navigator.of(context).pop,
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Cancel',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCompletionStatusOption({
    required String label,
    required String value,
    required IconData icon,
  }) {
    // Check the appropriate completion status based on pickup/delivery
    final completionStatus = widget.isPickup
        ? _pickupCompletionStatus
        : _deliveryCompletionStatus;
    // Only show as selected if explicitly set to this value (not null)
    final isSelected = completionStatus != null && completionStatus == value;
    final color = value == 'complete' ? green : Colors.orange;

    return GestureDetector(
      onTap: () {
        setState(() {
          // Explicitly set the value when user taps - no auto-selection
          if (widget.isPickup) {
            _pickupCompletionStatus = value;
          } else {
            _deliveryCompletionStatus = value;
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
          if (value == 'success') {
            _selectedReason = null;
            _showCustomReason = false;
            _customReason = '';
            // Don't clear image for pickup success as it's needed
            if (!widget.isPickup) {
              _selectedImage = null;
            }
          } else {
            // Reset completion status when switching to failed
            if (widget.isPickup) {
              _pickupCompletionStatus = null;
              _notesController.clear();
            } else {
              _deliveryCompletionStatus = null;
            }
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

  Widget _buildDeliveryConfirmationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name of Receiver (Required)
        Text(
          'Full Name of Receiver',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: green,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _receiverNameController,
          decoration: InputDecoration(
            hintText: 'Enter receiver\'s full name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Receiver Signature
        Text(
          'Receiver Signature',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: green,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.white,
              width: double.infinity,
              height: 150,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                _signatureController.clear();
              },
              child: Text(
                'Clear',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Upload Proof of Delivery (POD) - Required
        _buildFileUploadButton(
          label: 'Upload Proof of Delivery (POD)',
          subtitle: '(Required - PDF, JPEG, or PNG)',
          file: _podFile,
          onTap: _pickPODFile,
          isRequired: true,
          onRemove: () {
            setState(() {
              _podFile = null;
            });
          },
        ),
        const SizedBox(height: 16),

        // Take Photo of Deliver & Location - Recommended
        _buildFileUploadButton(
          label: 'Take Photo of Deliver & Location',
          subtitle: '(Recommended)',
          file: _deliveryPhoto,
          onTap: _pickDeliveryPhoto,
          isRequired: false,
          onRemove: () {
            setState(() {
              _deliveryPhoto = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFileUploadButton({
    required String label,
    required String subtitle,
    required dynamic file,
    required VoidCallback onTap,
    required bool isRequired,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: green.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.upload_file,
                  color: file != null ? green : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (file != null && onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (file != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.file_present, size: 16, color: green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file is XFile
                            ? (file as XFile).name
                            : (file as File).path.split('/').last,
                        style: TextStyle(
                          fontSize: 12,
                          color: green,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickPODFile() async {
    try {
      // Show options for file picker or camera
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _podFile = image; // Store XFile directly
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDeliveryPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _deliveryPhoto = image; // Store XFile directly
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show options for camera or gallery
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image; // Store XFile directly
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    // Prevent multiple submissions
    if (_isSubmitting) return;

    // Helper function to show error - use dialog for better visibility in modal bottom sheet
    Future<void> showErrorDialog(String message) async {
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Validation Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(message, style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
    }

    // Also show snackbar as backup
    void showErrorSnackbar(String message) {
      if (mounted) {
        // Use the current context directly since we're in a modal
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            elevation: 6,
          ),
        );
      }
    }

    try {
      // First, validate that a status (success/failed) is selected
      if (_selectedStatus.isEmpty ||
          (_selectedStatus != 'success' && _selectedStatus != 'failed')) {
        final message = widget.isPickup
            ? 'Please select a status: Picked Up or Failed'
            : 'Please select a status: Delivered or Failed';
        await showErrorDialog(message);
        showErrorSnackbar(message);
        return;
      }

      // Validate - MUST select completion status for pickup success
      if (widget.isPickup && _selectedStatus == 'success') {
        if (_pickupCompletionStatus == null ||
            (_pickupCompletionStatus != 'complete' &&
                _pickupCompletionStatus != 'partial')) {
          const message =
              'Please select Pickup Status: Complete or Partial Success';
          await showErrorDialog(message);
          showErrorSnackbar(message);
          return;
        }
      }

      // Validate delivery fields (for both success and failed)
      if (!widget.isPickup) {
        if (_selectedStatus == 'success') {
          // Validate completion status for delivery success
          if (_deliveryCompletionStatus == null ||
              (_deliveryCompletionStatus != 'complete' &&
                  _deliveryCompletionStatus != 'partial')) {
            const message =
                'Please select Delivery Status: Complete or Partial Success';
            await showErrorDialog(message);
            showErrorSnackbar(message);
            return;
          }

          // Validate partial success reason if status is partial
          if (_deliveryCompletionStatus == 'partial') {
            if (_partialSuccessReason == null) {
              const message = 'Please select a reason for Partial Success';
              await showErrorDialog(message);
              showErrorSnackbar(message);
              return;
            }

            if (_showPartialSuccessCustomReason &&
                _partialSuccessCustomReason.trim().isEmpty) {
              const message = 'Please provide a reason for Partial Success';
              await showErrorDialog(message);
              showErrorSnackbar(message);
              return;
            }
          }

          // Validate required fields for delivery success
          if (_receiverNameController.text.trim().isEmpty) {
            const message = 'Please enter receiver\'s full name';
            await showErrorDialog(message);
            showErrorSnackbar(message);
            return;
          }

          if (_podFile == null) {
            const message = 'Please upload Proof of Delivery (POD)';
            await showErrorDialog(message);
            showErrorSnackbar(message);
            return;
          }

          if (_signatureController.isEmpty) {
            const message = 'Please provide receiver\'s signature';
            await showErrorDialog(message);
            showErrorSnackbar(message);
            return;
          }
        } else if (_selectedStatus == 'failed') {
          // Validation for delivery failure is handled below in the failure section
        }
      }

      // Validate failure reasons (for both pickup and delivery failures)
      if (_selectedStatus == 'failed') {
        if (_selectedReason == null) {
          final message = widget.isPickup
              ? 'Please select a reason for pickup failure'
              : 'Please select a reason for delivery failure';
          await showErrorDialog(message);
          showErrorSnackbar(message);
          return;
        }

        if (_showCustomReason && _customReason.trim().isEmpty) {
          const message = 'Please provide a reason for failure';
          await showErrorDialog(message);
          showErrorSnackbar(message);
          return;
        }
      }
    } catch (e) {
      await FirebaseService.recordError(
        e,
        StackTrace.current,
        reason: 'Validation error in confirmation dialog',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier == null) {
        throw Exception('Carrier not found');
      }

      // Upload POD file and delivery photo for delivery
      String? podUrl;
      String? deliveryPhotoUrl;

      if (!widget.isPickup) {
        // Upload POD file (required)
        if (_podFile != null) {
          try {
            final ref = FirebaseService.storage.ref().child(
              'loads/${widget.loadId}/delivery_pod_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );

            UploadTask uploadTask;
            if (kIsWeb) {
              final xfile = _podFile as XFile;
              final bytes = await xfile.readAsBytes();
              uploadTask = ref.putData(
                bytes,
                SettableMetadata(contentType: 'image/jpeg'),
              );
            } else {
              final file = _podFile is XFile
                  ? File((_podFile as XFile).path)
                  : _podFile as File;
              uploadTask = ref.putFile(file);
            }

            final snapshot = await uploadTask;
            podUrl = await snapshot.ref.getDownloadURL();
          } catch (e) {
            print('Error uploading POD: $e');
            throw Exception('Failed to upload Proof of Delivery');
          }
        }

        // Upload delivery photo (optional)
        if (_deliveryPhoto != null) {
          try {
            final ref = FirebaseService.storage.ref().child(
              'loads/${widget.loadId}/delivery_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );

            UploadTask uploadTask;
            if (kIsWeb) {
              final xfile = _deliveryPhoto as XFile;
              final bytes = await xfile.readAsBytes();
              uploadTask = ref.putData(
                bytes,
                SettableMetadata(contentType: 'image/jpeg'),
              );
            } else {
              final file = _deliveryPhoto is XFile
                  ? File((_deliveryPhoto as XFile).path)
                  : _deliveryPhoto as File;
              uploadTask = ref.putFile(file);
            }

            final snapshot = await uploadTask;
            deliveryPhotoUrl = await snapshot.ref.getDownloadURL();
          } catch (e) {
            print('Error uploading delivery photo: $e');
            // Continue even if delivery photo upload fails
          }
        }
      }

      // Upload image if provided (for pickup or failures)
      String? imageUrl;
      if (_selectedImage != null) {
        try {
          // Upload image - different path for success vs failure
          final imageType = _selectedStatus == 'success'
              ? 'confirmation'
              : 'failure';
          final ref = FirebaseService.storage.ref().child(
            'loads/${widget.loadId}/${widget.locationType}_${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          UploadTask uploadTask;
          if (kIsWeb) {
            final xfile = _selectedImage as XFile;
            final bytes = await xfile.readAsBytes();
            uploadTask = ref.putData(
              bytes,
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else {
            final file = _selectedImage is XFile
                ? File((_selectedImage as XFile).path)
                : _selectedImage as File;
            uploadTask = ref.putFile(file);
          }

          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();

          // Log image upload success
          await FirebaseService.logEvent(
            'load_${imageType}_image_uploaded',
            parameters: {
              'load_id': widget.loadId,
              'location_type': widget.locationType,
            },
          );
        } catch (e) {
          print('Error uploading image: $e');
          await FirebaseService.recordError(
            e,
            StackTrace.current,
            reason: 'Failed to upload image in marketplace screen',
          );
          // Continue without image if upload fails
        }
      }

      // Store pickup confirmation data if pickup success
      if (widget.isPickup && _selectedStatus == 'success') {
        // Ensure completion status is set (validation should have caught null, but double-check)
        if (_pickupCompletionStatus == null) {
          throw Exception('Pickup completion status must be selected');
        }

        final confirmationData = {
          'loadId': widget.loadId,
          'carrierUid': carrier.uid,
          'completionStatus': _pickupCompletionStatus!,
          'notes': _notesController.text.trim(),
          'imageUrl': imageUrl,
          'confirmedAt': Timestamp.now(),
          'createdAt': Timestamp.now(),
        };

        try {
          await FirebaseService.firestore
              .collection('pickup_confirmations')
              .add(confirmationData);
        } catch (e) {
          print('Error storing pickup confirmation: $e');
          // Continue even if storing confirmation fails
        }
      }

      // Store delivery confirmation data (only for delivery success)
      if (!widget.isPickup && _selectedStatus == 'success') {
        // Ensure completion status is set (validation should have caught null, but double-check)
        if (_deliveryCompletionStatus == null) {
          throw Exception('Delivery completion status must be selected');
        }

        // Convert signature to image and upload
        String? signatureUrl;
        if (!_signatureController.isEmpty) {
          try {
            final signatureData = await _signatureController.toPngBytes();
            if (signatureData != null) {
              // Upload signature to Firebase Storage
              final ref = FirebaseService.storage.ref().child(
                'loads/${widget.loadId}/delivery_signature_${DateTime.now().millisecondsSinceEpoch}.png',
              );

              String? downloadUrl;
              if (kIsWeb) {
                final uploadTask = ref.putData(
                  signatureData,
                  SettableMetadata(contentType: 'image/png'),
                );
                final snapshot = await uploadTask;
                downloadUrl = await snapshot.ref.getDownloadURL();
              } else {
                // Save signature as temporary file
                final tempDir = Directory.systemTemp;
                final signatureFile = File(
                  '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
                );
                await signatureFile.writeAsBytes(signatureData);

                final uploadTask = ref.putFile(signatureFile);
                final snapshot = await uploadTask;
                downloadUrl = await snapshot.ref.getDownloadURL();

                // Clean up temp file
                try {
                  await signatureFile.delete();
                } catch (e) {
                  // Ignore cleanup errors
                }
              }
              signatureUrl = downloadUrl;
            }
          } catch (e) {
            print('Error uploading signature: $e');
            await FirebaseService.recordError(
              e,
              StackTrace.current,
              reason: 'Failed to upload delivery signature',
            );
            // Continue even if signature upload fails
          }
        }

        final deliveryConfirmationData = {
          'loadId': widget.loadId,
          'carrierUid': carrier.uid,
          'completionStatus': _deliveryCompletionStatus!,
          'receiverName': _receiverNameController.text.trim(),
          'signatureUrl': signatureUrl,
          'podUrl': podUrl,
          'deliveryPhotoUrl': deliveryPhotoUrl,
          'partialSuccessReason': _deliveryCompletionStatus == 'partial'
              ? (_showPartialSuccessCustomReason
                    ? _partialSuccessCustomReason
                    : _partialSuccessReason)
              : null,
          'notes': _deliveryNotes.trim().isNotEmpty
              ? _deliveryNotes.trim()
              : null,
          'confirmedAt': Timestamp.now(),
          'createdAt': Timestamp.now(),
        };

        try {
          await FirebaseService.firestore
              .collection('delivery_confirmations')
              .add(deliveryConfirmationData);

          // Log analytics
          await FirebaseService.logEvent(
            'delivery_confirmation_stored',
            parameters: {
              'load_id': widget.loadId,
              'completion_status': _deliveryCompletionStatus!,
              'has_pod': podUrl != null ? 1 : 0,
              'has_delivery_photo': deliveryPhotoUrl != null ? 1 : 0,
              'has_signature': signatureUrl != null ? 1 : 0,
            },
          );
        } catch (e) {
          print('Error storing delivery confirmation: $e');
          await FirebaseService.recordError(
            e,
            StackTrace.current,
            reason: 'Failed to store delivery confirmation',
          );
          // Continue even if storing confirmation fails
        }
      }

      // Determine new status
      String newStatus;
      if (widget.isPickup) {
        // For pickup, check selected status
        if (_selectedStatus == 'success') {
          newStatus = 'in-transit';
        } else {
          newStatus = 'booked'; // Keep as booked for failures
        }
      } else {
        // For delivery, check selected status
        if (_selectedStatus == 'success') {
          newStatus = 'completed';
        } else {
          newStatus = 'in-transit'; // Keep as in-transit for delivery failures
        }
      }

      // Update load status
      if (_selectedStatus == 'success') {
        try {
          await FirebaseService.updateCarrierLoadStatus(
            loadId: widget.loadId,
            status: newStatus,
            carrierUid: carrier.uid,
          );

          // Log analytics for success
          await FirebaseService.logEvent(
            'load_${widget.locationType}_success',
            parameters: {
              'load_id': widget.loadId,
              'completion_status': widget.isPickup
                  ? (_pickupCompletionStatus ?? 'unknown')
                  : (_deliveryCompletionStatus ?? 'unknown'),
            },
          );
        } catch (e) {
          await FirebaseService.recordError(
            e,
            StackTrace.current,
            reason: 'Failed to update load status to $newStatus',
          );
          rethrow;
        }
      }

      // Store failure reason and image if it's a failure (for both pickup and delivery)
      if (_selectedStatus == 'failed') {
        final reason = _showCustomReason ? _customReason : _selectedReason;

        // Store failure information in Firestore
        try {
          final failureData = {
            'loadId': widget.loadId,
            'locationType': widget.locationType,
            'reason': reason ?? 'Unknown',
            'customReason': _showCustomReason ? _customReason : null,
            'imageUrl': imageUrl,
            'timestamp': DateTime.now().toIso8601String(),
            'carrierUid': carrier.uid,
          };

          await FirebaseService.firestore
              .collection('load_failures')
              .add(failureData);

          // Log analytics for failure
          await FirebaseService.logEvent(
            'load_${widget.locationType}_failed',
            parameters: {
              'load_id': widget.loadId,
              'reason': reason ?? 'Unknown',
              'has_image': imageUrl != null ? 1 : 0,
              'is_custom_reason': _showCustomReason ? 1 : 0,
            },
          );
        } catch (e) {
          print('Error storing failure data: $e');
          await FirebaseService.recordError(
            e,
            StackTrace.current,
            reason: 'Failed to store load failure data',
          );
          // Continue even if storing fails
        }
      }

      // Success - update UI state and close dialog
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        Navigator.of(context).pop();
        widget.onStatusUpdated();

        // Show success message using root context
        try {
          final rootContext = Navigator.of(
            context,
            rootNavigator: true,
          ).context;
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(
              content: Text(
                _selectedStatus == 'success'
                    ? (widget.isPickup
                          ? 'Pickup confirmed successfully'
                          : 'Delivery confirmed successfully')
                    : 'Failure reason recorded',
              ),
              backgroundColor: green,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (e) {
          // Fallback to current context if root context fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedStatus == 'success'
                    ? (widget.isPickup
                          ? 'Pickup confirmed successfully'
                          : 'Delivery confirmed successfully')
                    : 'Failure reason recorded',
              ),
              backgroundColor: green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Reset loading state on error
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }

      // Log error to Crashlytics
      await FirebaseService.recordError(
        e,
        StackTrace.current,
        reason:
            'Failed to ${widget.isPickup ? "confirm pickup" : "confirm delivery"}',
      );

      // Log analytics for error
      await FirebaseService.logEvent(
        'load_confirmation_error',
        parameters: {
          'load_id': widget.loadId,
          'location_type': widget.locationType,
          'error_type': e.runtimeType.toString(),
          'error_message': e.toString(),
        },
      );

      if (mounted) {
        String errorMessage = 'Failed to update status';

        // Provide user-friendly error messages
        if (e.toString().contains('Load not found')) {
          errorMessage = 'Load not found. Please refresh and try again.';
        } else if (e.toString().contains('Unauthorized')) {
          errorMessage = 'You do not have permission to update this load.';
        } else if (e.toString().contains('Carrier not found')) {
          errorMessage = 'Carrier information not found. Please log in again.';
        } else if (e.toString().contains('Validation error')) {
          errorMessage = e.toString();
        } else {
          errorMessage = 'Failed to update status: ${e.toString()}';
        }

        // Show error dialog
        await showErrorDialog(errorMessage);

        // Also show snackbar
        try {
          final rootContext = Navigator.of(
            context,
            rootNavigator: true,
          ).context;
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (e) {
          // Fallback to current context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}
