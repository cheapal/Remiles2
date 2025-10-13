import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/shipper_model.dart';
import '../models/carrier_model.dart';
import '../core/firebase_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  UserRole? get userRole => _currentUser?.role;

  // Specific user type getters
  ShipperModel? get shipperUser {
    if (_currentUser is ShipperModel) {
      return _currentUser as ShipperModel;
    }
    return null;
  }

  CarrierModel? get carrierUser {
    if (_currentUser is CarrierModel) {
      return _currentUser as CarrierModel;
    }
    return null;
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load current user data
  Future<void> loadCurrentUser() async {
    try {
      _setLoading(true);
      _setError(null);

      final userData = await FirebaseService.getCurrentUserData();
      _currentUser = userData;
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;

    try {
      _setLoading(true);
      _setError(null);

      final uid = _currentUser!.uid;
      final role = _currentUser!.role;

      switch (role) {
        case UserRole.shipper:
          await FirebaseService.updateShipper(uid, updates);
          break;
        case UserRole.carrier:
          await FirebaseService.updateCarrier(uid, updates);
          break;
      }

      // Reload user data to get updated information
      await loadCurrentUser();
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update shipper-specific data
  Future<void> updateShipperProfile(Map<String, dynamic> updates) async {
    if (shipperUser == null) return;

    try {
      _setLoading(true);
      _setError(null);

      await FirebaseService.updateShipper(shipperUser!.uid, updates);
      await loadCurrentUser();
    } catch (e) {
      _setError('Failed to update shipper profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update carrier-specific data
  Future<void> updateCarrierProfile(Map<String, dynamic> updates) async {
    if (carrierUser == null) return;

    try {
      _setLoading(true);
      _setError(null);

      await FirebaseService.updateCarrier(carrierUser!.uid, updates);
      await loadCurrentUser();
    } catch (e) {
      _setError('Failed to update carrier profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Set user data (called by AuthProvider after login)
  void setUser(UserModel user) {
    _currentUser = user;
    _setError(null);
    notifyListeners();
  }

  // Clear user data (called by AuthProvider after logout)
  void clearUser() {
    _currentUser = null;
    _setError(null);
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUser() async {
    await loadCurrentUser();
  }

  // Get user display name
  String getDisplayName() {
    if (_currentUser == null) return 'Guest';
    
    switch (_currentUser!.role) {
      case UserRole.shipper:
        final shipper = shipperUser;
        return shipper?.companyName ?? shipper?.displayName ?? _currentUser!.email;
      case UserRole.carrier:
        final carrier = carrierUser;
        return carrier?.companyName ?? carrier?.displayName ?? _currentUser!.email;
    }
  }

  // Get user profile image
  String? getProfileImageUrl() {
    return _currentUser?.profileImageUrl;
  }

  // Check if user is verified
  bool isUserVerified() {
    if (_currentUser == null) return false;
    
    switch (_currentUser!.role) {
      case UserRole.shipper:
        return shipperUser?.isVerified ?? false;
      case UserRole.carrier:
        return carrierUser?.isVerified ?? false;
    }
  }

  // Get user rating
  double? getUserRating() {
    if (_currentUser == null) return null;
    
    switch (_currentUser!.role) {
      case UserRole.shipper:
        return shipperUser?.rating;
      case UserRole.carrier:
        return carrierUser?.rating;
    }
  }

  // Get user statistics
  Map<String, dynamic> getUserStats() {
    if (_currentUser == null) return {};

    switch (_currentUser!.role) {
      case UserRole.shipper:
        final shipper = shipperUser;
        return {
          'totalShipments': shipper?.totalShipments ?? 0,
          'rating': shipper?.rating ?? 0.0,
          'isVerified': shipper?.isVerified ?? false,
        };
      case UserRole.carrier:
        final carrier = carrierUser;
        return {
          'totalDeliveries': carrier?.totalDeliveries ?? 0,
          'rating': carrier?.rating ?? 0.0,
          'isVerified': carrier?.isVerified ?? false,
          'isAvailable': carrier?.isAvailable ?? false,
        };
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
