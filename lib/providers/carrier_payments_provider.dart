import 'package:flutter/foundation.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider to manage carrier payments (payments received by carriers)
class CarrierPaymentsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  DateTime? _lastPaymentsFetch;
  String? _currentUserId; // Track current user to detect user changes
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Getters
  List<Map<String, dynamic>> get payments => List.unmodifiable(_payments);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasPayments => _payments.isNotEmpty;

  /// Check if payments cache is still valid
  bool get _isPaymentsCacheValid {
    if (_lastPaymentsFetch == null) return false;
    return DateTime.now().difference(_lastPaymentsFetch!) < _cacheValidDuration;
  }

  /// Load carrier payments (with caching)
  /// [forceRefresh] - if true, bypasses cache and fetches fresh data
  Future<void> loadPayments({
    bool forceRefresh = false,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Check if user changed - if so, clear cache immediately
    final currentUser = FirebaseService.currentUser;
    final currentUserId = currentUser?.uid;
    
    if (currentUserId != null && _currentUserId != null && _currentUserId != currentUserId) {
      // User changed - clear all data immediately
      debugPrint('User changed from $_currentUserId to $currentUserId - clearing carrier payments cache');
      clear();
    }
    
    // Update tracked user ID
    _currentUserId = currentUserId;
    
    // If no user is logged in, clear data and return
    if (currentUserId == null) {
      clear();
      return;
    }
    
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isPaymentsCacheValid && _payments.isNotEmpty) {
      return;
    }

    // If we have cached data, refresh in background
    if (_payments.isNotEmpty && !forceRefresh) {
      _refreshPaymentsInBackground(fromDate: fromDate, toDate: toDate);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Try to get payments from transfers collection first
      Query query = FirebaseService.firestore
          .collection('transfers')
          .where('carrierId', isEqualTo: currentUser.uid)
          .limit(200); // Get more to filter in memory

      QuerySnapshot snapshot;
      try {
        // Try with orderBy first
        query = query.orderBy('createdAt', descending: true);
        snapshot = await query.get();
        debugPrint('Carrier payments: Loaded ${snapshot.docs.length} transfers with orderBy');
      } catch (e) {
        debugPrint('Carrier payments: orderBy failed, trying without orderBy: $e');
        // If orderBy fails (no index), try without it
        try {
          query = FirebaseService.firestore
              .collection('transfers')
              .where('carrierId', isEqualTo: currentUser.uid)
              .limit(200);
          snapshot = await query.get();
          debugPrint('Carrier payments: Loaded ${snapshot.docs.length} transfers without orderBy');
        } catch (e2) {
          debugPrint('Carrier payments: Query failed, trying fallback: $e2');
          // If transfers collection doesn't exist or has no index, try alternative approach
          // Get payments from completed bookings
          await _loadPaymentsFromBookings(currentUser.uid, fromDate, toDate);
          return;
        }
      }

      if (snapshot.docs.isEmpty) {
        debugPrint('Carrier payments: No transfers found, trying fallback to bookings');
        // Fallback to loading from bookings
        await _loadPaymentsFromBookings(currentUser.uid, fromDate, toDate);
        return;
      }

      // First, collect all shipper IDs that need names fetched
      final shipperIdsToFetch = <String>{};
      final paymentsData = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final shipperId = data['shipperId'] as String?;
        final shipperName = data['shipperName'] as String?;
        
        // If shipperName is missing, we'll need to fetch it
        if (shipperId != null && (shipperName == null || shipperName.isEmpty)) {
          shipperIdsToFetch.add(shipperId);
        }
        
        // Convert amount: amountInCents is in cents, amount is in dollars
        final amountInCents = data['amountInCents'] as int?;
        final amountDollars = data['amount'] as num?;
        final amount = amountInCents ?? 
            (amountDollars != null ? (amountDollars * 100).toInt() : 0);
        
        // Get transfer ID from stripeTransferId or use doc ID
        final transferId = data['stripeTransferId'] ?? 
                          data['transferId'] ?? 
                          doc.id;
        
        // Normalize status: "completed" should be treated as "succeeded"
        final status = data['status'] as String? ?? 'pending';
        final normalizedStatus = (status.toLowerCase() == 'completed') 
            ? 'succeeded' 
            : status;
        
        paymentsData.add({
          'id': doc.id,
          'transferId': transferId,
          'amount': amount, // Always in cents
          'currency': data['currency'] ?? 'usd',
          'status': normalizedStatus,
          'shipperId': shipperId,
          'shipperName': shipperName, // Will be updated if missing
          'loadId': data['loadId'],
          'loadNumber': data['loadNumber'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
          'succeededAt': (data['succeededAt'] as Timestamp?)?.toDate() ??
                        (data['completedAt'] as Timestamp?)?.toDate() ??
                        (data['createdAt'] as Timestamp?)?.toDate(),
          'failedAt': (data['failedAt'] as Timestamp?)?.toDate(),
          'failureReason': data['failureReason'],
          'metadata': data,
        });
      }
      
      // Fetch shipper names for those that are missing
      final shipperNamesCache = <String, String>{};
      if (shipperIdsToFetch.isNotEmpty) {
        debugPrint('Carrier payments: Fetching ${shipperIdsToFetch.length} shipper names');
        final shipperFutures = shipperIdsToFetch.map((shipperId) async {
          try {
            final shipperDoc = await FirebaseService.firestore
                .collection('shippers')
                .doc(shipperId)
                .get();
            
            if (shipperDoc.exists) {
              final shipperData = shipperDoc.data();
              final companyName = shipperData?['companyName'] as String?;
              final displayName = shipperData?['displayName'] as String?;
              final name = shipperData?['name'] as String?;
              final shipperName = companyName?.isNotEmpty == true 
                  ? companyName! 
                  : (displayName?.isNotEmpty == true 
                      ? displayName! 
                      : (name?.isNotEmpty == true ? name! : 'Unknown Shipper'));
              return MapEntry(shipperId, shipperName);
            }
          } catch (e) {
            debugPrint('Error fetching shipper name for $shipperId: $e');
          }
          return MapEntry(shipperId, 'Unknown Shipper');
        });
        
        final shipperResults = await Future.wait(shipperFutures);
        for (final entry in shipperResults) {
          shipperNamesCache[entry.key] = entry.value;
        }
      }
      
      // Update payments with fetched shipper names
      var allPayments = paymentsData.map((payment) {
        final shipperId = payment['shipperId'] as String?;
        final currentName = payment['shipperName'] as String?;
        
        if ((currentName == null || currentName.isEmpty || currentName == 'Unknown Shipper') 
            && shipperId != null 
            && shipperNamesCache.containsKey(shipperId)) {
          payment['shipperName'] = shipperNamesCache[shipperId]!;
        } else if (currentName == null || currentName.isEmpty) {
          payment['shipperName'] = 'Unknown Shipper';
        }
        
        return payment;
      }).toList();

      // Apply date filters in memory
      if (fromDate != null || toDate != null) {
        allPayments = allPayments.where((payment) {
          final paymentDate = payment['succeededAt'] as DateTime? ??
              payment['completedAt'] as DateTime? ??
              payment['createdAt'] as DateTime?;
          
          if (paymentDate == null) return false;
          
          if (fromDate != null && paymentDate.isBefore(fromDate)) {
            return false;
          }
          
          if (toDate != null) {
            final endOfDay = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
            if (paymentDate.isAfter(endOfDay)) {
              return false;
            }
          }
          
          return true;
        }).toList();
      }

      _payments = allPayments;

      _lastPaymentsFetch = DateTime.now();
      
      await FirebaseService.log('Carrier payments loaded successfully - Count: ${_payments.length}');
      await FirebaseService.logEvent(
        'carrier_payments_loaded',
        parameters: FirebaseService.convertParameters({
          'count': _payments.length,
          'force_refresh': forceRefresh ? 1 : 0,
          'has_date_filter': (fromDate != null || toDate != null) ? 1 : 0,
        }),
      );
    } catch (e, stackTrace) {
      debugPrint('Error loading carrier payments: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to load carrier payments',
      );
      // Try fallback to bookings
      try {
        final currentUser = FirebaseService.currentUser;
        if (currentUser != null) {
          await _loadPaymentsFromBookings(currentUser.uid, fromDate, toDate);
        }
      } catch (e2) {
        debugPrint('Fallback also failed: $e2');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load payments from completed bookings (fallback method)
  Future<void> _loadPaymentsFromBookings(
    String carrierId,
    DateTime? fromDate,
    DateTime? toDate,
  ) async {
    try {
      // Try to load completed bookings first
      Query query = FirebaseService.firestore
          .collection('bookings')
          .where('carrierId', isEqualTo: carrierId)
          .where('status', isEqualTo: 'completed')
          .limit(200);

      QuerySnapshot snapshot;
      try {
        // Try with orderBy first
        query = query.orderBy('completedAt', descending: true);
        snapshot = await query.get();
        debugPrint('Carrier payments: Loaded ${snapshot.docs.length} completed bookings');
      } catch (e) {
        debugPrint('Carrier payments: orderBy failed for completed bookings, trying without: $e');
        // If orderBy fails, try without it
        query = FirebaseService.firestore
            .collection('bookings')
            .where('carrierId', isEqualTo: carrierId)
            .where('status', isEqualTo: 'completed')
            .limit(200);
        snapshot = await query.get();
        debugPrint('Carrier payments: Loaded ${snapshot.docs.length} completed bookings without orderBy');
      }
      
      // If no completed bookings found, also try 'booked' status
      if (snapshot.docs.isEmpty) {
        debugPrint('Carrier payments: No completed bookings, trying booked status');
        try {
          query = FirebaseService.firestore
              .collection('bookings')
              .where('carrierId', isEqualTo: carrierId)
              .where('status', isEqualTo: 'booked')
              .limit(200);
          snapshot = await query.get();
          debugPrint('Carrier payments: Loaded ${snapshot.docs.length} booked bookings');
        } catch (e) {
          debugPrint('Carrier payments: Failed to load booked bookings: $e');
        }
      }
      
      // Get load details for each booking
      final paymentsList = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final bookingData = doc.data() as Map<String, dynamic>;
        final loadId = bookingData['loadId'] as String?;
        final shipperId = bookingData['shipperId'] as String?;
        
        if (loadId != null && shipperId != null) {
          try {
            // Loads are stored in shippers/{shipperId}/loads/{loadId}
            final loadDoc = await FirebaseService.firestore
                .collection('shippers')
                .doc(shipperId)
                .collection('loads')
                .doc(loadId)
                .get();
            
            if (loadDoc.exists) {
              final loadData = loadDoc.data() as Map<String, dynamic>;
              final price = loadData['price'] ?? 0;
              // Convert price to cents if it's in dollars
              final amountInCents = price is int 
                  ? (price > 1000 ? price : price * 100) // If > 1000, assume already in cents
                  : (price is double ? (price * 100).toInt() : 0);
              
              final completedAt = (bookingData['completedAt'] as Timestamp?)?.toDate() ?? 
                                  (bookingData['updatedAt'] as Timestamp?)?.toDate();
              
              paymentsList.add({
                'id': doc.id,
                'transferId': 'BK-${doc.id.substring(0, 8)}',
                'amount': amountInCents,
                'currency': 'usd',
                'status': 'succeeded', // Completed bookings are considered succeeded
                'shipperId': shipperId,
                'shipperName': bookingData['shipperName'] ?? loadData['shipperName'] ?? 'Unknown Shipper',
                'loadId': loadId,
                'loadNumber': loadData['loadNumber'] ?? loadId.substring(0, 8),
                'createdAt': (bookingData['bookedAt'] as Timestamp?)?.toDate(),
                'completedAt': completedAt,
                'succeededAt': completedAt,
                'metadata': {
                  'bookingId': doc.id,
                  'loadId': loadId,
                },
              });
            } else {
              debugPrint('Load document not found: shippers/$shipperId/loads/$loadId');
            }
          } catch (e) {
            debugPrint('Error loading load details for booking ${doc.id}: $e');
          }
        } else {
          debugPrint('Booking ${doc.id} missing loadId or shipperId');
        }
      }
      
      debugPrint('Carrier payments from bookings: Found ${paymentsList.length} payments');
      
      // Apply date filters in memory
      if (fromDate != null || toDate != null) {
        paymentsList.removeWhere((payment) {
          final paymentDate = payment['succeededAt'] as DateTime? ??
              payment['completedAt'] as DateTime? ??
              payment['createdAt'] as DateTime?;
          
          if (paymentDate == null) return true;
          
          if (fromDate != null && paymentDate.isBefore(fromDate)) {
            return true;
          }
          
          if (toDate != null) {
            final endOfDay = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
            if (paymentDate.isAfter(endOfDay)) {
              return true;
            }
          }
          
          return false;
        });
      }
      
      _payments = paymentsList;
      _lastPaymentsFetch = DateTime.now();
      
      await FirebaseService.log('Carrier payments loaded from bookings - Count: ${_payments.length}');
    } catch (e, stackTrace) {
      debugPrint('Error loading payments from bookings: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to load carrier payments from bookings',
      );
      _payments = [];
    }
  }

  /// Refresh payments in background (silent refresh)
  Future<void> _refreshPaymentsInBackground({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    try {
      await loadPayments(forceRefresh: true, fromDate: fromDate, toDate: toDate);
    } catch (e) {
      debugPrint('Background payments refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// Invalidate cache (force next load to fetch fresh data)
  void invalidateCache() {
    _lastPaymentsFetch = null;
  }

  /// Clear all data
  void clear() {
    _payments = [];
    _lastPaymentsFetch = null;
    _currentUserId = null; // Clear user tracking
    notifyListeners();
  }
}
