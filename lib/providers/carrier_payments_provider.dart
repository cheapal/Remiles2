import 'package:flutter/foundation.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider to manage carrier payments (payments received by carriers)
class CarrierPaymentsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  DateTime? _lastPaymentsFetch;
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
          .orderBy('createdAt', descending: true)
          .limit(200); // Get more to filter in memory

      QuerySnapshot snapshot;
      try {
        snapshot = await query.get();
      } catch (e) {
        // If transfers collection doesn't exist or has no index, try alternative approach
        // Get payments from completed bookings
        await _loadPaymentsFromBookings(currentUser.uid, fromDate, toDate);
        return;
      }

      if (snapshot.docs.isEmpty) {
        // Fallback to loading from bookings
        await _loadPaymentsFromBookings(currentUser.uid, fromDate, toDate);
        return;
      }

      List<Map<String, dynamic>> allPayments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'transferId': data['transferId'] ?? doc.id,
          'amount': data['amount'] ?? 0,
          'currency': data['currency'] ?? 'usd',
          'status': data['status'] ?? 'pending',
          'shipperId': data['shipperId'],
          'shipperName': data['shipperName'] ?? 'Unknown Shipper',
          'loadId': data['loadId'],
          'loadNumber': data['loadNumber'],
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
          'succeededAt': (data['succeededAt'] as Timestamp?)?.toDate(),
          'failedAt': (data['failedAt'] as Timestamp?)?.toDate(),
          'failureReason': data['failureReason'],
          'metadata': data['metadata'],
        };
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
      // Load all completed bookings, then filter in memory
      Query query = FirebaseService.firestore
          .collection('bookings')
          .where('carrierId', isEqualTo: carrierId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(200);

      QuerySnapshot snapshot;
      try {
        snapshot = await query.get();
      } catch (e) {
        // If orderBy fails, try without it
        query = FirebaseService.firestore
            .collection('bookings')
            .where('carrierId', isEqualTo: carrierId)
            .where('status', isEqualTo: 'completed')
            .limit(200);
        snapshot = await query.get();
      }
      
      // Get load details for each booking
      final paymentsList = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final bookingData = doc.data() as Map<String, dynamic>;
        final loadId = bookingData['loadId'] as String?;
        
        if (loadId != null) {
          try {
            final loadDoc = await FirebaseService.loads.doc(loadId).get();
            if (loadDoc.exists) {
              final loadData = loadDoc.data() as Map<String, dynamic>;
              final price = loadData['price'] ?? 0;
              
              final completedAt = (bookingData['completedAt'] as Timestamp?)?.toDate() ?? 
                                  (bookingData['updatedAt'] as Timestamp?)?.toDate();
              
              paymentsList.add({
                'id': doc.id,
                'transferId': 'BK-${doc.id.substring(0, 8)}',
                'amount': price is int ? price : (price is double ? (price * 100).toInt() : 0),
                'currency': 'usd',
                'status': 'succeeded', // Completed bookings are considered succeeded
                'shipperId': bookingData['shipperId'],
                'shipperName': bookingData['shipperName'] ?? 'Unknown Shipper',
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
            }
          } catch (e) {
            debugPrint('Error loading load details for booking ${doc.id}: $e');
          }
        }
      }
      
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
    notifyListeners();
  }
}
