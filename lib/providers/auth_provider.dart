import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/shipper_model.dart';
import '../models/carrier_model.dart';
import '../core/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseUser != null && _currentUser != null;
  bool get isInitialized => _isInitialized;
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

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setUser(User? firebaseUser, UserModel? userModel) {
    _firebaseUser = firebaseUser;
    _currentUser = userModel;
    notifyListeners();
  }

  // Public method to set user data (for external use)
  void setUserData(User? firebaseUser, UserModel? userModel) {
    _setUser(firebaseUser, userModel);
  }

  // Initialize authentication state
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      _setError(null);

      // Listen to Firebase Auth state changes
      FirebaseService.authStateChanges.listen((User? user) async {
        if (user != null) {
          await _loadUserData(user);
        } else {
          _setUser(null, null);
          await _clearStoredAuth();
        }
      });

      // Check if user is already logged in
      final currentFirebaseUser = FirebaseService.currentUser;
      if (currentFirebaseUser != null) {
        await _loadUserData(currentFirebaseUser);
      }

      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize authentication: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(User firebaseUser) async {
    try {
      final userData = await FirebaseService.getCurrentUserData();
      if (userData != null) {
        print('AuthProvider: Loaded user data: ${userData.toString()}');
        if (userData is ShipperModel) {
          print('AuthProvider: Loaded shipper with isOnboardingComplete: ${userData.isOnboardingComplete}');
        }
        _setUser(firebaseUser, userData);
        await _storeAuthData(userData);
      } else {
        // User exists in Firebase Auth but not in Firestore
        await signOut();
      }
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
    }
  }

  // Store authentication data
  Future<void> _storeAuthData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', user.uid);
      await prefs.setString('user_role', user.role.toString().split('.').last);
      await prefs.setString('user_email', user.email);
    } catch (e) {
      debugPrint('Failed to store auth data: $e');
    }
  }

  // Clear stored authentication data
  Future<void> _clearStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_uid');
      await prefs.remove('user_role');
      await prefs.remove('user_email');
    } catch (e) {
      debugPrint('Failed to clear auth data: $e');
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final userCredential = await FirebaseService.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userCredential?.user != null) {
        // Load user data immediately after login
        await _loadUserData(userCredential!.user!);
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up shipper
  Future<bool> signUpShipper({
    required String email,
    required String password,
    required String companyName,
    String? displayName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final shipperData = ShipperModel(
        uid: '', // Will be set by Firebase
        email: email,
        displayName: displayName ?? companyName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        companyName: companyName,
        additionalData: additionalData,
        isOnboardingComplete: false, // Explicitly set to false
      );
      
      print('AuthProvider: Creating shipper with isOnboardingComplete: ${shipperData.isOnboardingComplete}');

      final userCredential = await FirebaseService.signUpShipper(
        email: email,
        password: password,
        shipperData: shipperData,
      );

      if (userCredential?.user != null) {
        // Load user data immediately after signup
        await _loadUserData(userCredential!.user!);
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Sign up failed: ${e.message}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('Sign up failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up carrier
  Future<bool> signUpCarrier({
    required String email,
    required String password,
    required String companyName,
    String? displayName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final carrierData = CarrierModel(
        uid: '', // Will be set by Firebase
        email: email,
        displayName: displayName ?? companyName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        companyName: companyName,
        additionalData: additionalData,
        isOnboardingComplete: false, // Mark onboarding as incomplete
      );

      final userCredential = await FirebaseService.signUpCarrier(
        email: email,
        password: password,
        carrierData: carrierData,
      );

      if (userCredential?.user != null) {
        // Load user data immediately after signup
        await _loadUserData(userCredential!.user!);
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Sign up failed: ${e.message}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('Sign up failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _setError(null);

      await FirebaseService.signOut();
      _setUser(null, null);
      await _clearStoredAuth();
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await FirebaseService.auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Failed to send reset email: ${e.message}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError('Failed to send reset email: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error message
  void clearError() {
    _setError(null);
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_firebaseUser != null) {
      await _loadUserData(_firebaseUser!);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
