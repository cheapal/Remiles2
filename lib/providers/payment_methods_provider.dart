import 'package:flutter/foundation.dart';
import 'package:Remiles/core/stripe_service.dart';
import 'package:Remiles/core/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider to manage payment methods with caching
class PaymentMethodsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  DateTime? _lastPaymentMethodsFetch;
  DateTime? _lastTransactionsFetch;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Getters
  List<Map<String, dynamic>> get paymentMethods => List.unmodifiable(_paymentMethods);
  List<Map<String, dynamic>> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasPaymentMethods => _paymentMethods.isNotEmpty;
  bool get hasTransactions => _transactions.isNotEmpty;

  /// Check if payment methods cache is still valid
  bool get _isPaymentMethodsCacheValid {
    if (_lastPaymentMethodsFetch == null) return false;
    return DateTime.now().difference(_lastPaymentMethodsFetch!) < _cacheValidDuration;
  }

  /// Check if transactions cache is still valid
  bool get _isTransactionsCacheValid {
    if (_lastTransactionsFetch == null) return false;
    return DateTime.now().difference(_lastTransactionsFetch!) < _cacheValidDuration;
  }

  /// Load payment methods (with caching)
  /// [forceRefresh] - if true, bypasses cache and fetches fresh data
  Future<void> loadPaymentMethods({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isPaymentMethodsCacheValid && _paymentMethods.isNotEmpty) {
      // Log cache hit
      await FirebaseService.logEvent(
        'payment_methods_cache_hit',
        parameters: FirebaseService.convertParameters({
          'cache_age_minutes': DateTime.now().difference(_lastPaymentMethodsFetch!).inMinutes,
        }),
      );
      return;
    }

    // If we have cached data, refresh in background
    if (_paymentMethods.isNotEmpty && !forceRefresh) {
      _refreshPaymentMethodsInBackground();
      return;
    }

    // Otherwise, show loading and fetch
    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService.log('Loading payment methods${forceRefresh ? ' (force refresh)' : ''}');
      
      final methods = await StripeService.listPaymentMethods();
      _paymentMethods = methods;
      _lastPaymentMethodsFetch = DateTime.now();

      // Log success
      await FirebaseService.log('Payment methods loaded successfully - Count: ${methods.length}');
      await FirebaseService.setCustomKey('payment_methods_count', methods.length);
      await FirebaseService.logEvent(
        'payment_methods_loaded',
        parameters: FirebaseService.convertParameters({
          'count': methods.length,
          'force_refresh': forceRefresh ? 1 : 0,
          'cache_used': (!forceRefresh && _paymentMethods.isNotEmpty) ? 1 : 0,
        }),
      );
    } catch (e, stackTrace) {
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to load payment methods',
      );
      await FirebaseService.log('Payment methods load failed: $e');
      await FirebaseService.setCustomKey('payment_methods_load_error', e.toString());
      await FirebaseService.logEvent(
        'payment_methods_load_failed',
        parameters: FirebaseService.convertParameters({
          'error_type': e.runtimeType.toString(),
          'force_refresh': forceRefresh ? 1 : 0,
        }),
      );
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh payment methods in background (silent refresh)
  Future<void> _refreshPaymentMethodsInBackground() async {
    if (_isRefreshing) return; // Already refreshing

    _isRefreshing = true;
    try {
      final methods = await StripeService.listPaymentMethods();
      _paymentMethods = methods;
      _lastPaymentMethodsFetch = DateTime.now();
      
      // Log background refresh success
      await FirebaseService.log('Payment methods background refresh successful - Count: ${methods.length}');
      await FirebaseService.logEvent(
        'payment_methods_background_refresh',
        parameters: FirebaseService.convertParameters({
          'count': methods.length,
        }),
      );
      
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Background refresh failed: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Background payment methods refresh failed',
      );
      await FirebaseService.log('Payment methods background refresh failed: $e');
      // Don't show error for background refresh
    } finally {
      _isRefreshing = false;
    }
  }

  /// Load transactions (with caching)
  /// [forceRefresh] - if true, bypasses cache and fetches fresh data
  Future<void> loadTransactions({
    bool forceRefresh = false,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isTransactionsCacheValid && _transactions.isNotEmpty) {
      return;
    }

    // If we have cached data, refresh in background
    if (_transactions.isNotEmpty && !forceRefresh) {
      _refreshTransactionsInBackground(fromDate: fromDate, toDate: toDate);
      return;
    }

    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) return;

      Query query = FirebaseService.firestore
          .collection('payment_intents')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(50);

      // Apply date filters if set
      if (fromDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }
      if (toDate != null) {
        final endOfDay = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }

      final snapshot = await query.get();
      _transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'paymentIntentId': data['paymentIntentId'] ?? 'N/A',
          'amount': data['amount'] ?? 0,
          'currency': data['currency'] ?? 'usd',
          'status': data['status'] ?? 'unknown',
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'succeededAt': (data['succeededAt'] as Timestamp?)?.toDate(),
          'failedAt': (data['failedAt'] as Timestamp?)?.toDate(),
          'failureReason': data['failureReason'],
          'metadata': data['metadata'],
        };
      }).toList();

      _lastTransactionsFetch = DateTime.now();
      
      // Log success
      await FirebaseService.log('Transactions loaded successfully - Count: ${_transactions.length}');
      await FirebaseService.setCustomKey('transactions_count', _transactions.length);
      await FirebaseService.logEvent(
        'transactions_loaded',
        parameters: FirebaseService.convertParameters({
          'count': _transactions.length,
          'force_refresh': forceRefresh ? 1 : 0,
          'has_date_filter': (fromDate != null || toDate != null) ? 1 : 0,
        }),
      );
      
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error loading transactions: $e');
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to load transactions',
      );
      await FirebaseService.log('Transactions load failed: $e');
      await FirebaseService.setCustomKey('transactions_load_error', e.toString());
      await FirebaseService.logEvent(
        'transactions_load_failed',
        parameters: FirebaseService.convertParameters({
          'error_type': e.runtimeType.toString(),
          'force_refresh': forceRefresh ? 1 : 0,
        }),
      );
    }
  }

  /// Refresh transactions in background (silent refresh)
  Future<void> _refreshTransactionsInBackground({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    try {
      await loadTransactions(forceRefresh: true, fromDate: fromDate, toDate: toDate);
    } catch (e) {
      debugPrint('Background transactions refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// Add payment method (optimistic update)
  Future<bool> addPaymentMethod() async {
    try {
      await FirebaseService.log('Adding payment method');
      await FirebaseService.logEvent(
        'payment_method_add_attempted',
        parameters: FirebaseService.convertParameters({}),
      );

      final success = await StripeService.savePaymentMethod();
      if (success) {
        // Invalidate cache and reload
        _lastPaymentMethodsFetch = null;
        await loadPaymentMethods(forceRefresh: true);

        // Log success
        await FirebaseService.log('Payment method added successfully');
        await FirebaseService.setCustomKey('payment_methods_count', _paymentMethods.length);
        await FirebaseService.logEvent(
          'payment_method_added',
          parameters: FirebaseService.convertParameters({
            'total_methods': _paymentMethods.length,
          }),
        );
      }
      return success;
    } catch (e, stackTrace) {
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to add payment method',
      );
      await FirebaseService.log('Payment method add failed: $e');
      await FirebaseService.setCustomKey('payment_method_add_error', e.toString());
      await FirebaseService.logEvent(
        'payment_method_add_failed',
        parameters: FirebaseService.convertParameters({
          'error_type': e.runtimeType.toString(),
        }),
      );
      rethrow;
    }
  }

  /// Set default payment method (optimistic update)
  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      await FirebaseService.log('Setting default payment method: $paymentMethodId');
      await FirebaseService.logEvent(
        'payment_method_set_default_attempted',
        parameters: FirebaseService.convertParameters({
          'payment_method_id': paymentMethodId,
        }),
      );

      // Optimistic update
      _paymentMethods = _paymentMethods.map((method) {
        return {
          ...method,
          'isDefault': method['id'] == paymentMethodId,
        };
      }).toList();
      notifyListeners();

      await StripeService.setDefaultPaymentMethod(paymentMethodId);

      // Reload to ensure consistency
      await loadPaymentMethods(forceRefresh: true);

      // Log success
      await FirebaseService.log('Default payment method set successfully');
      await FirebaseService.setCustomKey('default_payment_method_id', paymentMethodId);
      await FirebaseService.logEvent(
        'payment_method_set_default',
        parameters: FirebaseService.convertParameters({
          'payment_method_id': paymentMethodId,
        }),
      );
    } catch (e, stackTrace) {
      // Revert optimistic update on error
      await loadPaymentMethods(forceRefresh: true);
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to set default payment method',
      );
      await FirebaseService.log('Set default payment method failed: $e');
      await FirebaseService.setCustomKey('set_default_payment_method_error', e.toString());
      await FirebaseService.logEvent(
        'payment_method_set_default_failed',
        parameters: FirebaseService.convertParameters({
          'payment_method_id': paymentMethodId,
          'error_type': e.runtimeType.toString(),
        }),
      );
      rethrow;
    }
  }

  /// Delete payment method (optimistic update)
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      final methodToDelete = _paymentMethods.firstWhere(
        (method) => method['id'] == paymentMethodId,
        orElse: () => {},
      );
      final wasDefault = methodToDelete['isDefault'] == true;
      final cardBrand = methodToDelete['card']?['brand'] ?? 'unknown';

      await FirebaseService.log('Deleting payment method: $paymentMethodId');
      await FirebaseService.logEvent(
        'payment_method_delete_attempted',
        parameters: FirebaseService.convertParameters({
          'payment_method_id': paymentMethodId,
          'was_default': wasDefault ? 1 : 0,
          'card_brand': cardBrand,
        }),
      );

      // Optimistic update
      _paymentMethods.removeWhere((method) => method['id'] == paymentMethodId);

      // If deleted method was default and there are other methods, set first as default
      if (wasDefault && _paymentMethods.isNotEmpty) {
        _paymentMethods[0]['isDefault'] = true;
      }

      notifyListeners();

      await StripeService.deletePaymentMethod(paymentMethodId);

      // Reload to ensure consistency
      await loadPaymentMethods(forceRefresh: true);

      // Log success
      await FirebaseService.log('Payment method deleted successfully');
      await FirebaseService.setCustomKey('payment_methods_count', _paymentMethods.length);
      await FirebaseService.logEvent(
        'payment_method_deleted',
        parameters: FirebaseService.convertParameters({
          'payment_method_id': paymentMethodId,
          'was_default': wasDefault ? 1 : 0,
          'card_brand': cardBrand,
          'remaining_methods': _paymentMethods.length,
        }),
      );
    } catch (e, stackTrace) {
      // Revert optimistic update on error
      await loadPaymentMethods(forceRefresh: true);
      await FirebaseService.recordError(
        e,
        stackTrace,
        reason: 'Failed to delete payment method',
      );
      await FirebaseService.log('Delete payment method failed: $e');
      await FirebaseService.setCustomKey('delete_payment_method_error', e.toString());
      await FirebaseService.logEvent(
        'payment_method_delete_failed',
        parameters: FirebaseService.convertParameters({
          'payment_method_id': paymentMethodId,
          'error_type': e.runtimeType.toString(),
        }),
      );
      rethrow;
    }
  }

  /// Invalidate cache (force next load to fetch fresh data)
  void invalidateCache() {
    _lastPaymentMethodsFetch = null;
    _lastTransactionsFetch = null;
  }

  /// Clear all data
  void clear() {
    _paymentMethods = [];
    _transactions = [];
    _lastPaymentMethodsFetch = null;
    _lastTransactionsFetch = null;
    notifyListeners();
  }
}

