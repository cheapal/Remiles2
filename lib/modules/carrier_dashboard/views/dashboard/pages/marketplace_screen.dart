
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/custom_progress_bar.dart';
import 'package:Remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:provider/provider.dart';
import 'package:Remiles/providers/auth_provider.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:Remiles/models/load_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Remiles/modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import 'package:geolocator/geolocator.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
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

  @override
  void initState() {
    super.initState();
    // Load booked loads first
    _loadBookedLoads();
  }

  Future<void> _loadBookedLoads() async {
    try {
      // Log analytics event
      await FirebaseService.logEvent('load_booked_loads_started', parameters: {
        'screen': 'marketplace',
      });

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
        final filteredLoads = allLoads.where((load) => 
          load.bookedByCarrierId == carrier.uid
        ).toList();
        
        // Log analytics
        await FirebaseService.logEvent('loads_loaded', parameters: {
          'screen': 'marketplace',
          'total_loads': filteredLoads.length,
        });
        
        setState(() {
          _bookedLoads = filteredLoads;
          _isLoadingLoads = false;
          
          // Select first load by default if available
          if (_bookedLoads.isNotEmpty) {
            _selectedLoad = _bookedLoads.first;
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
      
      await FirebaseService.logEvent('loads_load_error', parameters: {
        'screen': 'marketplace',
        'error': e.toString(),
      });
      
      if (mounted) {
        setState(() {
          _isLoadingLoads = false;
          _errorMessage = 'Failed to load loads: ${e.toString()}';
        });
      }
    }
  }

  void _updateLoadData() async {
    if (_selectedLoad == null) return;
    
    final load = _selectedLoad!;
    
    // Reset map state first and update location data
    setState(() {
      // Update location data immediately
      _shipperName = load.shipperName;
      _pickupAddress = "${load.originAddress}, ${load.originCity}, ${load.originState}";
      _deliveryAddress = "${load.destinationAddress}, ${load.destinationCity}, ${load.destinationState}";
      
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
    });
    
    // Fetch shipper phone number
    try {
      final shipper = await FirebaseService.getShipper(load.shipperUid);
      if (mounted) {
        setState(() {
          if (shipper != null && shipper.phoneNumber != null && shipper.phoneNumber!.isNotEmpty) {
            _shipperPhone = shipper.phoneNumber!;
          } else {
            _shipperPhone = "";
          }
        });
      }
    } catch (e) {
      print('Error fetching shipper phone: $e');
      if (mounted) {
        setState(() {
          _shipperPhone = "";
        });
      }
    }
    
    // Initialize map with new load data
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Log analytics event
      await FirebaseService.logEvent('map_initialization_started', parameters: {
        'screen': 'marketplace',
        'load_id': _selectedLoad?.id ?? 'none',
      });

      // Geocode addresses to get coordinates
      await _geocodeAddresses();
      
      // Only proceed if we have valid locations
      if (_pickupLocation == null || _deliveryLocation == null) {
        await FirebaseService.recordError(
          Exception('Failed to geocode addresses'),
          StackTrace.current,
          reason: 'Geocoding failed in marketplace screen',
        );
        await FirebaseService.logEvent('geocoding_failed', parameters: {
          'screen': 'marketplace',
          'load_id': _selectedLoad?.id ?? 'none',
        });
        
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
      await FirebaseService.logEvent('map_initialized', parameters: {
        'screen': 'marketplace',
        'load_id': _selectedLoad?.id ?? 'none',
        'has_route': _routePoints.isNotEmpty ? 1 : 0, // Convert bool to int for analytics
      });
      
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
      
      await FirebaseService.logEvent('map_initialization_error', parameters: {
        'screen': 'marketplace',
        'error': e.toString(),
      });
      
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
        List<Location> pickupLocations = await locationFromAddress(_pickupAddress);
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
        List<Location> deliveryLocations = await locationFromAddress(_deliveryAddress);
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
      const String apiKey = 'AIzaSyAOZKD90SxW5dwOZVEe-nCm8dA6jXs-5AQ';
      
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
                    if (step['polyline'] != null && step['polyline']['points'] != null) {
                      final stepPolyline = step['polyline']['points'];
                      final decodedStepPoints = decodePolyline(stepPolyline);
                      final stepLatLngs = decodedStepPoints
                          .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
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
            } else if (route['overview_polyline'] != null && route['overview_polyline']['points'] != null) {
              // Fallback to overview polyline if detailed steps aren't available
              final polyline = route['overview_polyline']['points'];
              final decodedPoints = decodePolyline(polyline);
              _routePoints = decodedPoints
                  .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
                  .toList();
            } else {
              // Last resort: straight line
              _routePoints = [_pickupLocation!, _deliveryLocation!];
            }
            
            // Log successful route fetch
            await FirebaseService.logEvent('route_fetched', parameters: {
              'screen': 'marketplace',
              'load_id': _selectedLoad?.id ?? 'none',
              'route_points_count': _routePoints.length,
              'route_type': allRoutePoints.isNotEmpty ? 'detailed' : 'overview',
            });
          } else {
            // Log API error with detailed information
            final errorStatus = data['status']?.toString() ?? 'UNKNOWN';
            final errorMessage = data['error_message']?.toString() ?? 'No error message';
            
            print('Google Directions API error: $errorStatus - $errorMessage');
            await FirebaseService.log('Google Directions API error: $errorStatus - $errorMessage');
            await FirebaseService.logEvent('route_api_error', parameters: {
              'screen': 'marketplace',
              'status': errorStatus,
              'error_message': errorMessage,
            });
            
            // Show user-friendly error message for common issues
            if (errorStatus == 'REQUEST_DENIED') {
              print('⚠️ Directions API is not enabled. Enable it at: https://console.cloud.google.com/apis/library/directions-backend.googleapis.com');
            } else if (errorStatus == 'OVER_QUERY_LIMIT') {
              print('⚠️ Directions API quota exceeded. Check billing at: https://console.cloud.google.com/billing');
            }
            
            // Don't use straight line fallback - show error instead
            _routePoints = [];
          }
        } else {
          await FirebaseService.log('Route API HTTP error: ${response.statusCode}');
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
            _activeLocation == 'shipper' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen,
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
            _activeLocation == 'pickup' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueBlue,
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
            _activeLocation == 'delivery' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
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
    
    // Map status to progress percentage
    switch (status) {
      case 'booked':
        _progress = 0.1; // Just booked, 10% complete
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  Future<void> _getCurrentLocation() async {
    try {
      // Log analytics event
      await FirebaseService.logEvent('location_permission_requested', parameters: {
        'screen': 'marketplace',
        'load_id': _selectedLoad?.id ?? 'none',
      });

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
        await FirebaseService.logEvent('location_service_disabled', parameters: {
          'screen': 'marketplace',
        });
        
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
          await FirebaseService.logEvent('location_permission_denied', parameters: {
            'screen': 'marketplace',
          });
          
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
          reason: 'User permanently denied location permission in marketplace screen',
        );
        
        // Log analytics
        await FirebaseService.logEvent('location_permission_denied_forever', parameters: {
          'screen': 'marketplace',
        });
        
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
      await FirebaseService.logEvent('location_retrieved', parameters: {
        'screen': 'marketplace',
        'load_id': _selectedLoad?.id ?? 'none',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      });

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
      await FirebaseService.logEvent('location_error', parameters: {
        'screen': 'marketplace',
        'error': e.toString(),
      });
      
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
              content: Text('Cannot make phone call. Please check if your device supports phone calls.'),
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
    
    // Determine which status pills should be active based on load status
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
      
      double minLat = allLocations.map((l) => l.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat = allLocations.map((l) => l.latitude).reduce((a, b) => a > b ? a : b);
      double minLng = allLocations.map((l) => l.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng = allLocations.map((l) => l.longitude).reduce((a, b) => a > b ? a : b);
      
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // screenshot background is dark/black
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Load ID Dropdown
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, bottom: 20),
                        child: Row(
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
                          ],
                        ),
                      ),

                      // --- Top status pills (based on load status) ---
                      _buildStatusPills(),

                      const SizedBox(height: 20),

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
                                    valueColor: AlwaysStoppedAnimation<Color>(green),
                                  ),
                                )
                              : _errorMessage != null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.red),
                                          const SizedBox(height: 8),
                                          Text(
                                            _errorMessage!,
                                            style: const TextStyle(color: Colors.red),
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
                                      : _pickupLocation != null && _deliveryLocation != null
                                          ? GoogleMap(
                                              key: ValueKey('map_${_routePoints.length}_${_selectedLoad?.id}'), // Force rebuild when route changes
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
                                                    valueColor: AlwaysStoppedAnimation<Color>(green),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _activeLocation == 'shipper' ? blue : green,
                                        width: _activeLocation == 'shipper' ? 3 : 2,
                                      ),
                                    boxShadow: [
                                      BoxShadow(
                                          color: (_activeLocation == 'shipper' ? blue : green).withOpacity(0.18),
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                    child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Shipper",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                            color: _activeLocation == 'shipper' ? blue : Colors.black,
                                        ),
                                      ),
                                        const SizedBox(height: 8),
                                      _shipperName.isNotEmpty 
                                          ? Text(
                                              _shipperPhone.isNotEmpty
                                                  ? "$_shipperName\n$_shipperPhone"
                                                  : _shipperName,
                                              style: const TextStyle(fontSize: 16),
                                            )
                                          : Row(
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(green),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Loading shipper info...',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey.shade600,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _activeLocation == 'pickup' ? blue : Colors.white,
                                        width: _activeLocation == 'pickup' ? 3 : 2,
                                      ),
                                      boxShadow: _activeLocation == 'pickup'
                                          ? [
                                              BoxShadow(
                                                color: blue.withOpacity(0.18),
                                                blurRadius: 4,
                                                spreadRadius: 0.5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pickup",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                            color: _activeLocation == 'pickup' ? blue : Colors.black,
                                        ),
                                      ),
                                        const SizedBox(height: 8),
                                      _pickupAddress.isNotEmpty 
                                          ? Text(
                                              _pickupAddress,
                                              style: const TextStyle(fontSize: 16),
                                            )
                                          : Row(
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(green),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Loading address...',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey.shade600,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _activeLocation == 'delivery' ? blue : Colors.white,
                                        width: _activeLocation == 'delivery' ? 3 : 2,
                                      ),
                                      boxShadow: _activeLocation == 'delivery'
                                          ? [
                                              BoxShadow(
                                                color: blue.withOpacity(0.18),
                                                blurRadius: 4,
                                                spreadRadius: 0.5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Delivery",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: _activeLocation == 'delivery' ? blue : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      _deliveryAddress.isNotEmpty 
                                          ? Text(
                                              _deliveryAddress,
                                              style: const TextStyle(fontSize: 16),
                                            )
                                          : Row(
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(green),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Loading address...',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey.shade600,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
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
                                        print('Call button pressed. Phone: $_shipperPhone');
                                        _makePhoneCall();
                                      }
                                    : () {
                                        print('Call button pressed but phone is empty');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Phone number not available'),
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
                                        print('Message button pressed. Load ID: ${_selectedLoad!.id}');
                                        _navigateToChat();
                                      }
                                    : null,
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
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
                      Row(
                        children: [
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: Colors.black45,
                            ),
                            child: const Text(
                              "Confirm Load\nDelivery",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
        border: Border.all( color: Colors.green.withOpacity(0.2),width: 1.4),
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
