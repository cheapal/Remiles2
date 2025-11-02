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
          // Allow new users (e.g., during Google Sign-In role selection)
          await _loadUserData(user, allowNewUser: true);
        } else {
          _setUser(null, null);
          await _clearStoredAuth();
        }
      });

      // Check if user is already logged in
      final currentFirebaseUser = FirebaseService.currentUser;
      if (currentFirebaseUser != null) {
        // During initialization, allow new users who might be in role selection
        await _loadUserData(currentFirebaseUser, allowNewUser: true);
      }

      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize authentication: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(User firebaseUser, {bool allowNewUser = false}) async {
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
        if (allowNewUser) {
          // Allow this for new users who need to select a role (e.g., Google Sign-In)
          print('AuthProvider: New user detected, keeping Firebase auth but no Firestore data yet');
          _setUser(firebaseUser, null);
        } else {
          // Only sign out if this is not expected (e.g., during initialization)
          print('AuthProvider: User not found in Firestore, signing out');
          await signOut();
        }
      }
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
      // If allowNewUser is true, don't clear the user on error
      if (!allowNewUser) {
        await signOut();
      }
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

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final userCredential = await FirebaseService.signInWithGoogle();

      if (userCredential?.user != null) {
        // Check if user exists in Firestore
        try {
          final userData = await FirebaseService.getCurrentUserData();
          
          if (userData == null) {
            // New user - they need to select a role
            // Set the Firebase user so they can continue to role selection
            // Keep the Firebase user authenticated but without Firestore data
            _setUser(userCredential!.user, null);
            // Return false to indicate new user needs role selection
            // Don't set error - this is expected for new users
            return false;
          } else {
            // Existing user - load their data
            await _loadUserData(userCredential!.user!, allowNewUser: false);
            return true;
          }
        } catch (e) {
          // If getCurrentUserData throws an error, check if it's because user doesn't exist
          // or if there's an actual error
          debugPrint('Error checking user data: $e');
          final user = userCredential!.user!;
          // Try to check user role directly
          final role = await FirebaseService.getUserRole(user.uid);
          if (role == null) {
            // User doesn't exist in Firestore, proceed to role selection
            // Keep Firebase user authenticated for role selection
            _setUser(user, null);
            return false;
          } else {
            // User exists, try to load again
            await _loadUserData(user, allowNewUser: false);
            return true;
          }
        }
      }

      // User canceled sign-in
      return false;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credential.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Google sign-in failed: ${e.message ?? e.code}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      // Handle other exceptions (PlatformException, etc.)
      final errorString = e.toString();
      String errorMessage;
      
      if (errorString.contains('sign_in_canceled') || errorString.contains('canceled')) {
        // User canceled - don't show error
        return false;
      } else if (errorString.contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (errorString.contains('SIGN_IN_REQUIRED') || errorString.contains('DEVELOPER_ERROR')) {
        errorMessage = 'Google Sign-In configuration error. Please check SHA-1 fingerprint in Firebase Console.';
      } else {
        errorMessage = 'Google sign-in failed: ${errorString}';
      }
      
      _setError(errorMessage);
      debugPrint('Google Sign-In error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create carrier account from Google Sign-In (user already authenticated)
  Future<bool> createCarrierFromGoogle({
    required String email,
    required String displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_firebaseUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      // Check if carrier already exists
      final existingCarrier = await FirebaseService.getCarrier(_firebaseUser!.uid);
      if (existingCarrier != null) {
        // Account already exists, just load it
        print('Carrier account already exists, loading existing data');
        await _loadUserData(_firebaseUser!);
        return true;
      }

      final carrierData = CarrierModel(
        uid: _firebaseUser!.uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        companyName: displayName, // Use displayName as company name for now
        profileImageUrl: photoUrl,
        isOnboardingComplete: false,
      );

      // Create carrier document in Firestore
      await FirebaseService.createCarrier(carrierData);

      // Load the created user data
      await _loadUserData(_firebaseUser!);

      return true;
    } catch (e) {
      debugPrint('Error creating carrier from Google: $e');
      _setError('Failed to create carrier account: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create shipper account from Google Sign-In (user already authenticated)
  Future<bool> createShipperFromGoogle({
    required String email,
    required String displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_firebaseUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      // Check if shipper already exists
      final existingShipper = await FirebaseService.getShipper(_firebaseUser!.uid);
      if (existingShipper != null) {
        // Account already exists, just load it
        print('Shipper account already exists, loading existing data');
        await _loadUserData(_firebaseUser!);
        return true;
      }

      final shipperData = ShipperModel(
        uid: _firebaseUser!.uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        companyName: displayName, // Use displayName as company name for now
        profileImageUrl: photoUrl,
        isOnboardingComplete: false,
      );

      // Create shipper document in Firestore
      await FirebaseService.createShipper(shipperData);

      // Load the created user data
      await _loadUserData(_firebaseUser!);

      return true;
    } catch (e) {
      debugPrint('Error creating shipper from Google: $e');
      _setError('Failed to create shipper account: ${e.toString()}');
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
