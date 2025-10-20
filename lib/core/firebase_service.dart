import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'app_config.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/shipper_model.dart';
import '../models/carrier_model.dart';
import '../models/carrier_onboarding_data.dart';
import '../models/shipper_onboarding_data.dart';

/// Firebase service class to handle all Firebase operations
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Authentication methods
  static FirebaseAuth get auth => _auth;
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore methods
  static FirebaseFirestore get firestore => _firestore;
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get shippers => _firestore.collection('shippers');
  static CollectionReference get carriers => _firestore.collection('carriers');
  static CollectionReference get loads => _firestore.collection('loads');

  // Storage methods
  static FirebaseStorage get storage => _storage;
  static Reference get storageRef => _storage.ref();

  // Analytics methods
  static FirebaseAnalytics get analytics => _analytics;
  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
  
  // Helper method to convert dynamic parameters to Object parameters
  static Map<String, Object> _convertParameters(Map<String, dynamic>? params) {
    if (params == null) return {};
    return params.map((key, value) => MapEntry(key, value as Object));
  }
  
  // Public version for external use
  static Map<String, Object> convertParameters(Map<String, dynamic>? params) {
    if (params == null) return {};
    return params.map((key, value) => MapEntry(key, value as Object));
  }
  
  // User properties for analytics
  static Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
  
  static Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }
  
  // Test method to verify analytics is working (debug only)
  static Future<void> testAnalytics() async {
    if (!AppConfig.enableTestEvents) {
      if (AppConfig.enableDebugLogging) {
        print('Analytics test skipped in ${AppConfig.buildMode} mode');
      }
      return;
    }
    
    try {
      await logEvent('analytics_test', parameters: _convertParameters({
        'test_timestamp': DateTime.now().millisecondsSinceEpoch,
        'test_success': true,
        'build_mode': AppConfig.buildMode,
        'app_version': AppConfig.versionInfo,
      }));
      if (AppConfig.enableDebugLogging) {
        print('Analytics test event logged successfully');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Analytics test failed: $e');
      }
    }
  }

  // Crashlytics methods
  static FirebaseCrashlytics get crashlytics => _crashlytics;
  static Future<void> recordError(dynamic exception, StackTrace? stackTrace, {String? reason}) async {
    await _crashlytics.recordError(exception, stackTrace, reason: reason);
  }

  // User management methods
  static Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Log successful sign in
      await logEvent('login', parameters: _convertParameters({
        'method': 'email_password',
        'success': true,
      }));
      return result;
    } catch (e) {
      // Log failed sign in
      await logEvent('login', parameters: _convertParameters({
        'method': 'email_password',
        'success': false,
        'error': e.toString(),
      }));
      await recordError(e, StackTrace.current, reason: 'Sign in failed');
      rethrow;
    }
  }

  static Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Log successful user creation
      await logEvent('sign_up', parameters: _convertParameters({
        'method': 'email_password',
        'success': true,
      }));
      return result;
    } catch (e) {
      // Log failed user creation
      await logEvent('sign_up', parameters: _convertParameters({
        'method': 'email_password',
        'success': false,
        'error': e.toString(),
      }));
      await recordError(e, StackTrace.current, reason: 'User creation failed');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Log successful sign out
      await logEvent('logout', parameters: _convertParameters({
        'success': true,
      }));
    } catch (e) {
      // Log failed sign out
      await logEvent('logout', parameters: _convertParameters({
        'success': false,
        'error': e.toString(),
      }));
      await recordError(e, StackTrace.current, reason: 'Sign out failed');
      rethrow;
    }
  }

  // Firestore data methods
  static Future<void> createUserDocument(String userId, Map<String, dynamic> userData) async {
    try {
      await users.doc(userId).set(userData);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Create user document failed');
      rethrow;
    }
  }

  static Future<DocumentSnapshot> getUserDocument(String userId) async {
    try {
      return await users.doc(userId).get();
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get user document failed');
      rethrow;
    }
  }

  static Future<void> updateUserDocument(String userId, Map<String, dynamic> updates) async {
    try {
      await users.doc(userId).update(updates);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Update user document failed');
      rethrow;
    }
  }

  // Storage methods
  // static Future<String> uploadFile(String path, List<int> data) async {
  //   try {
  //     final ref = _storage.ref().child(path);
  //     final uploadTask = await ref.putData(data);
  //     return await uploadTask.ref.getDownloadURL();
  //   } catch (e) {
  //     await recordError(e, StackTrace.current, reason: 'File upload failed');
  //     rethrow;
  //   }
  // }

  static Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'File deletion failed');
      rethrow;
    }
  }

  // Role-based user management methods
  static Future<ShipperModel?> createShipper(ShipperModel shipper) async {
    try {
      final docRef = shippers.doc(shipper.uid);
      await docRef.set(shipper.toFirestore());
      return shipper;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Create shipper failed');
      rethrow;
    }
  }

  static Future<CarrierModel?> createCarrier(CarrierModel carrier) async {
    try {
      final docRef = carriers.doc(carrier.uid);
      await docRef.set(carrier.toFirestore());
      return carrier;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Create carrier failed');
      rethrow;
    }
  }

  static Future<ShipperModel?> getShipper(String uid) async {
    try {
      final doc = await shippers.doc(uid).get();
      if (doc.exists) {
        return ShipperModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get shipper failed');
      rethrow;
    }
  }

  static Future<CarrierModel?> getCarrier(String uid) async {
    try {
      final doc = await carriers.doc(uid).get();
      if (doc.exists) {
        return CarrierModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get carrier failed');
      rethrow;
    }
  }

  static Future<void> updateShipper(String uid, Map<String, dynamic> updates) async {
    try {
      await shippers.doc(uid).update(updates);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Update shipper failed');
      rethrow;
    }
  }

  static Future<void> updateCarrier(String uid, Map<String, dynamic> updates) async {
    try {
      await carriers.doc(uid).update(updates);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Update carrier failed');
      rethrow;
    }
  }

  static Future<UserRole?> getUserRole(String uid) async {
    try {
      // Check shippers collection first
      final shipperDoc = await shippers.doc(uid).get();
      if (shipperDoc.exists) {
        return UserRole.shipper;
      }

      // Check carriers collection
      final carrierDoc = await carriers.doc(uid).get();
      if (carrierDoc.exists) {
        return UserRole.carrier;
      }

      return null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get user role failed');
      rethrow;
    }
  }

  static Future<UserModel?> getUserByRole(String uid, UserRole role) async {
    try {
      switch (role) {
        case UserRole.shipper:
          return await getShipper(uid);
        case UserRole.carrier:
          return await getCarrier(uid);
      }
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get user by role failed');
      rethrow;
    }
  }

  // Enhanced authentication methods with role handling
  static Future<UserCredential?> signUpShipper({
    required String email,
    required String password,
    required ShipperModel shipperData,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create shipper document in Firestore
        final shipper = shipperData.copyWithShipper(uid: userCredential.user!.uid);
        print('FirebaseService: Creating shipper with isOnboardingComplete: ${shipper.isOnboardingComplete}');
        await createShipper(shipper);
        print('FirebaseService: Shipper created successfully');
        
        // Set user properties for analytics
        await setUserId(userCredential.user!.uid);
        await setUserProperty('user_type', 'shipper');
        await setUserProperty('onboarding_complete', shipper.isOnboardingComplete.toString());
        
        // Log shipper signup event
        await logEvent('shipper_signup', parameters: _convertParameters({
          'success': true,
          'onboarding_complete': shipper.isOnboardingComplete,
        }));
      }

      return userCredential;
    } catch (e) {
      // Log failed shipper signup
      await logEvent('shipper_signup', parameters: _convertParameters({
        'success': false,
        'error': e.toString(),
      }));
      await recordError(e, StackTrace.current, reason: 'Shipper signup failed');
      rethrow;
    }
  }

  static Future<UserCredential?> signUpCarrier({
    required String email,
    required String password,
    required CarrierModel carrierData,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create carrier document in Firestore
        final carrier = carrierData.copyWithCarrier(uid: userCredential.user!.uid);
        await createCarrier(carrier);
        
        // Set user properties for analytics
        await setUserId(userCredential.user!.uid);
        await setUserProperty('user_type', 'carrier');
        await setUserProperty('onboarding_complete', carrier.isOnboardingComplete.toString());
        
        // Log carrier signup event
        await logEvent('carrier_signup', parameters: _convertParameters({
          'success': true,
          'onboarding_complete': carrier.isOnboardingComplete,
        }));
      }

      return userCredential;
    } catch (e) {
      // Log failed carrier signup
      await logEvent('carrier_signup', parameters: _convertParameters({
        'success': false,
        'error': e.toString(),
      }));
      await recordError(e, StackTrace.current, reason: 'Carrier signup failed');
      rethrow;
    }
  }

  static Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final role = await getUserRole(user.uid);
      if (role == null) return null;

      // Set user properties for analytics when getting current user data
      await setUserId(user.uid);
      await setUserProperty('user_type', role.name);
      
      final userData = await getUserByRole(user.uid, role);
      
      // Set additional user properties based on user type
      if (userData != null) {
        if (role == UserRole.shipper) {
          final shipper = userData as ShipperModel;
          await setUserProperty('onboarding_complete', shipper.isOnboardingComplete.toString());
        } else if (role == UserRole.carrier) {
          final carrier = userData as CarrierModel;
          await setUserProperty('onboarding_complete', carrier.isOnboardingComplete.toString());
        }
      }

      return userData;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get current user data failed');
      rethrow;
    }
  }

  // Carrier Onboarding Data Methods
  static Future<void> saveCarrierOnboardingResponse(
    String carrierId,
    String screenName,
    Map<String, dynamic> response,
  ) async {
    try {
      final carrierRef = carriers.doc(carrierId);
      final carrierDoc = await carrierRef.get();
      
      if (!carrierDoc.exists) {
        throw Exception('Carrier document not found');
      }
      
      final carrierData = carrierDoc.data() as Map<String, dynamic>;
      final currentOnboardingData = carrierData['onboardingData'] != null
          ? CarrierOnboardingData.fromFirestore(carrierData['onboardingData'])
          : CarrierOnboardingData();
      
      final updatedOnboardingData = currentOnboardingData.addResponse(screenName, response);
      
      await carrierRef.update({
        'onboardingData': updatedOnboardingData.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('Onboarding response saved for screen: $screenName');
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Save carrier onboarding response failed');
      rethrow;
    }
  }

  static Future<void> markCarrierOnboardingComplete(String carrierId) async {
    try {
      final carrierRef = carriers.doc(carrierId);
      final carrierDoc = await carrierRef.get();
      
      if (!carrierDoc.exists) {
        throw Exception('Carrier document not found');
      }
      
      final carrierData = carrierDoc.data() as Map<String, dynamic>;
      final currentOnboardingData = carrierData['onboardingData'] != null
          ? CarrierOnboardingData.fromFirestore(carrierData['onboardingData'])
          : CarrierOnboardingData();
      
      final completedOnboardingData = currentOnboardingData.markComplete();
      
      await carrierRef.update({
        'onboardingData': completedOnboardingData.toFirestore(),
        'isOnboardingComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Update user property for analytics
      await setUserProperty('onboarding_complete', 'true');
      
      // Log onboarding completion event
      await logEvent('onboarding_complete', parameters: _convertParameters({
        'user_type': 'carrier',
        'success': true,
      }));
      
      print('Carrier onboarding marked as complete');
    } catch (e) {
      // Log failed onboarding completion
      await logEvent('onboarding_complete', parameters: _convertParameters({
        'user_type': 'carrier',
        'success': false,
        'error': e.toString(),
      }));
      await recordError(e, StackTrace.current, reason: 'Mark carrier onboarding complete failed');
      rethrow;
    }
  }

  static Future<CarrierOnboardingData?> getCarrierOnboardingData(String carrierId) async {
    try {
      final carrierDoc = await carriers.doc(carrierId).get();
      
      if (!carrierDoc.exists) {
        return null;
      }
      
      final carrierData = carrierDoc.data() as Map<String, dynamic>;
      return carrierData['onboardingData'] != null
          ? CarrierOnboardingData.fromFirestore(carrierData['onboardingData'])
          : null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get carrier onboarding data failed');
      rethrow;
    }
  }

  static Future<bool> isCarrierOnboardingComplete(String carrierId) async {
    try {
      final onboardingData = await getCarrierOnboardingData(carrierId);
      return onboardingData?.isCompleted ?? false;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Check carrier onboarding complete failed');
      return false;
    }
  }

  static Future<List<String>> getCompletedOnboardingScreens(String carrierId) async {
    try {
      final onboardingData = await getCarrierOnboardingData(carrierId);
      return onboardingData?.completedScreens ?? [];
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get completed onboarding screens failed');
      return [];
    }
  }

  // Shipper Onboarding Data Methods
  static Future<void> saveShipperOnboardingResponse(
    String shipperId,
    String screenName,
    Map<String, dynamic> response,
  ) async {
    try {
      final shipperRef = shippers.doc(shipperId);
      final shipperDoc = await shipperRef.get();

      if (!shipperDoc.exists) {
        throw Exception('Shipper document not found');
      }

      final shipperData = shipperDoc.data() as Map<String, dynamic>;
      final currentOnboardingData = shipperData['onboardingData'] != null
          ? ShipperOnboardingData.fromFirestore(shipperData['onboardingData'])
          : const ShipperOnboardingData();

      final updatedOnboardingData = currentOnboardingData.addResponse(screenName, response);

      await shipperRef.update({
        'onboardingData': updatedOnboardingData.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Shipper onboarding response saved for screen: $screenName');
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Save shipper onboarding response failed');
      rethrow;
    }
  }

  static Future<void> markShipperOnboardingComplete(String shipperId) async {
    try {
      final shipperRef = shippers.doc(shipperId);
      final shipperDoc = await shipperRef.get();

      if (!shipperDoc.exists) {
        throw Exception('Shipper document not found');
      }

      final shipperData = shipperDoc.data() as Map<String, dynamic>;
      final currentOnboardingData = shipperData['onboardingData'] != null
          ? ShipperOnboardingData.fromFirestore(shipperData['onboardingData'])
          : const ShipperOnboardingData();

      final completedOnboardingData = currentOnboardingData.markComplete();

      await shipperRef.update({
        'onboardingData': completedOnboardingData.toFirestore(),
        'isOnboardingComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update user property for analytics
      await setUserProperty('onboarding_complete', 'true');
      
      // Log onboarding completion event
      await logEvent('onboarding_complete', parameters: _convertParameters({
        'user_type': 'shipper',
        'success': true,
      }));

      print('Shipper onboarding marked as complete');
    } catch (e) {
      // Log failed onboarding completion
      await logEvent('onboarding_complete', parameters: _convertParameters({
        'user_type': 'shipper',
        'success': false,
        'error': e.toString(),
      }));
      await recordError(e, StackTrace.current, reason: 'Mark shipper onboarding complete failed');
      rethrow;
    }
  }

  static Future<ShipperOnboardingData?> getShipperOnboardingData(String shipperId) async {
    try {
      final shipperDoc = await shippers.doc(shipperId).get();

      if (!shipperDoc.exists) {
        return null;
      }

      final shipperData = shipperDoc.data() as Map<String, dynamic>;
      return shipperData['onboardingData'] != null
          ? ShipperOnboardingData.fromFirestore(shipperData['onboardingData'])
          : null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get shipper onboarding data failed');
      rethrow;
    }
  }

  static Future<bool> isShipperOnboardingComplete(String shipperId) async {
    try {
      final onboardingData = await getShipperOnboardingData(shipperId);
      return onboardingData?.isCompleted ?? false;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Check shipper onboarding complete failed');
      return false;
    }
  }

  // Save shipper dashboard response
  static Future<void> saveShipperDashboardResponse(
    String shipperUid,
    String screenKey,
    Map<String, dynamic> response,
  ) async {
    try {
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('dashboard_responses')
          .doc(screenKey)
          .set(response, SetOptions(merge: true));
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to save shipper dashboard response');
      rethrow;
    }
  }

  // Get shipper dashboard response
  static Future<Map<String, dynamic>?> getShipperDashboardResponse(
    String shipperUid,
    String screenKey,
  ) async {
    try {
      final doc = await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('dashboard_responses')
          .doc(screenKey)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to get shipper dashboard response');
      return null;
    }
  }

  // Check if shipper has completed all dashboard steps
  static Future<bool> isShipperDashboardComplete(String shipperUid) async {
    try {
      // Check if all three dashboard steps are completed
      final dashboard2 = await getShipperDashboardResponse(shipperUid, 'dashboard_2_business_info');
      final dashboard3 = await getShipperDashboardResponse(shipperUid, 'dashboard_3_business_number');
      
      return dashboard2 != null && dashboard3 != null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Check shipper dashboard complete failed');
      return false;
    }
  }

  // Upload image to Firebase Storage
  static Future<String?> uploadImage(
    String shipperUid,
    String imageType,
    File imageFile,
  ) async {
    try {
      final ref = _storage.ref().child('shippers/$shipperUid/documents/$imageType.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to upload image');
      return null;
    }
  }

  // Upload load document to separate folder
  static Future<String?> uploadLoadDocument(
    String shipperUid,
    String loadId,
    File documentFile,
  ) async {
    try {
      // Get file name
      final fileName = documentFile.path.split('/').last;
      
      final ref = _storage.ref().child('shippers/$shipperUid/loads/$loadId/documents/$fileName');
      final uploadTask = ref.putFile(documentFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to upload load document');
      return null;
    }
  }

  // Save shipper load data
  static Future<void> saveShipperLoad(
    String shipperUid,
    Map<String, dynamic> loadData,
  ) async {
    try {
      final loadId = DateTime.now().millisecondsSinceEpoch.toString();
      loadData['id'] = loadId;
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .set(loadData);
      
      // Log load creation event
      await logEvent('load_created', parameters: _convertParameters({
        'load_id': loadId,
        'load_type': loadData['loadType'] ?? 'unknown',
        'equipment_needed': loadData['equipmentNeeded'] ?? 'unknown',
        'success': true,
      }));
    } catch (e) {
      // Log failed load creation
      await logEvent('load_created', parameters: _convertParameters({
        'success': false,
        'error': e.toString(),
      }));
      await recordError(e, StackTrace.current, reason: 'Failed to save shipper load');
      rethrow;
    }
  }

  // Update existing shipper load data
  static Future<void> updateShipperLoad(
    String shipperUid,
    String loadId,
    Map<String, dynamic> loadData,
  ) async {
    try {
      loadData['id'] = loadId;
      loadData['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .update(loadData);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to update shipper load');
      rethrow;
    }
  }

  // Save support ticket
  static Future<void> saveSupportTicket(
    String userId,
    Map<String, dynamic> supportData,
  ) async {
    try {
      final ticketId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .set(supportData);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to save support ticket');
      rethrow;
    }
  }

  // Save user preferences
  static Future<void> saveUserPreferences(
    String userId,
    Map<String, dynamic> preferencesData,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('user_preferences')
          .set(preferencesData, SetOptions(merge: true));
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to save user preferences');
      rethrow;
    }
  }

  // Get user preferences
  static Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('user_preferences')
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to get user preferences');
      return null;
    }
  }

  // Save shipper preferences (stored in shipper document)
  static Future<void> saveShipperPreferences(
    String shipperUid,
    Map<String, dynamic> preferencesData,
  ) async {
    try {
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .update({
        'preferences': preferencesData,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to save shipper preferences');
      rethrow;
    }
  }

  // Get shipper preferences (from shipper document)
  static Future<Map<String, dynamic>?> getShipperPreferences(String shipperUid) async {
    try {
      final doc = await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        return data?['preferences'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to get shipper preferences');
      return null;
    }
  }

  // Get shipper loads with search, filter, and pagination
  static Future<Map<String, dynamic>> getShipperLoads({
    required String shipperUid,
    String searchQuery = '',
    String status = 'all',
    String loadType = 'all',
    String equipmentType = 'all',
    String originCity = 'all',
    String destinationCity = 'all',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads');

      // Apply status filter
      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      // Apply load type filter
      if (loadType != 'all') {
        query = query.where('loadType', isEqualTo: loadType);
      }

      // Apply equipment type filter
      if (equipmentType != 'all') {
        query = query.where('equipmentNeeded', isEqualTo: equipmentType);
      }


      // Note: City filtering will be done client-side due to Firestore limitations
      // with compound queries and text search

      // Apply sorting
      query = query.orderBy(sortBy, descending: sortOrder == 'desc');

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Apply limit
      query = query.limit(limit);

      final snapshot = await query.get();
      final loads = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Apply search and city filters client-side
      final filteredLoads = loads.where((load) {
        // Apply search filter
        bool matchesSearch = true;
        if (searchQuery.isNotEmpty) {
          final searchLower = searchQuery.toLowerCase();
          matchesSearch = (load['originAddress']?.toString().toLowerCase().contains(searchLower) ?? false) ||
                         (load['destinationAddress']?.toString().toLowerCase().contains(searchLower) ?? false) ||
                         (load['loadType']?.toString().toLowerCase().contains(searchLower) ?? false) ||
                         (load['loadDescription']?.toString().toLowerCase().contains(searchLower) ?? false) ||
                         (load['equipmentNeeded']?.toString().toLowerCase().contains(searchLower) ?? false);
        }

        // Apply origin city filter
        bool matchesOriginCity = true;
        if (originCity != 'all') {
          matchesOriginCity = load['originAddress']?.toString().contains(originCity) ?? false;
        }

        // Apply destination city filter
        bool matchesDestinationCity = true;
        if (destinationCity != 'all') {
          matchesDestinationCity = load['destinationAddress']?.toString().contains(destinationCity) ?? false;
        }

        return matchesSearch && matchesOriginCity && matchesDestinationCity;
      }).toList();

      return {
        'loads': filteredLoads,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
        'totalCount': filteredLoads.length,
      };
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to get shipper loads');
      return {
        'loads': <Map<String, dynamic>>[],
        'lastDocument': null,
        'hasMore': false,
        'totalCount': 0,
      };
    }
  }

  // Get load statistics for shipper
  static Future<Map<String, int>> getShipperLoadStats(String shipperUid) async {
    try {
      final snapshot = await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .get();

      final stats = <String, int>{
        'active': 0,
        'inTransit': 0,
        'booked': 0,
        'cancelled': 0,
        'completed': 0,
        'total': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? 'active';
        
        stats['total'] = (stats['total'] ?? 0) + 1;
        
        if (stats.containsKey(status)) {
          stats[status] = (stats[status] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to get shipper load stats');
      return {
        'active': 0,
        'inTransit': 0,
        'booked': 0,
        'cancelled': 0,
        'completed': 0,
        'total': 0,
      };
    }
  }

  // Update load status
  static Future<void> updateLoadStatus(
    String shipperUid,
    String loadId,
    String newStatus,
  ) async {
    try {
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to update load status');
      rethrow;
    }
  }

  // Delete load and all associated documents
  static Future<void> deleteLoad(
    String shipperUid,
    String loadId,
  ) async {
    try {
      // First, get the load data to find document URLs
      final loadDoc = await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .get();
      
      if (loadDoc.exists) {
        final loadData = loadDoc.data();
        
        // Delete associated documents from Storage
        if (loadData != null) {
          // Delete additional document if it exists
          if (loadData['additionalDocument'] != null) {
            try {
              final documentUrl = loadData['additionalDocument'].toString();
              final ref = _storage.refFromURL(documentUrl);
              await ref.delete();
            } catch (e) {
              // Log error but don't fail the entire operation
              await recordError(e, StackTrace.current, reason: 'Failed to delete load document from storage');
            }
          }
        }
        
        // Also try to delete the entire load documents folder
        try {
          final loadDocumentsRef = _storage.ref().child('shippers/$shipperUid/loads/$loadId');
          final listResult = await loadDocumentsRef.listAll();
          
          // Delete all files in the load documents folder
          for (final item in listResult.items) {
            try {
              await item.delete();
            } catch (e) {
              // Log individual file deletion errors but continue
              await recordError(e, StackTrace.current, reason: 'Failed to delete individual load document file');
            }
          }
        } catch (e) {
          // Log folder deletion error but don't fail the entire operation
          await recordError(e, StackTrace.current, reason: 'Failed to delete load documents folder');
        }
      }
      
      // Delete the Firestore document
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .delete();
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to delete load');
      rethrow;
    }
  }

  // Mark load as booked
  static Future<void> markLoadAsBooked(
    String shipperUid,
    String loadId,
  ) async {
    try {
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .update({
        'isBooked': true,
        'status': 'booked', // Update status to booked
        'bookedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Log load booking event
      await logEvent('load_booked', parameters: _convertParameters({
        'load_id': loadId,
        'success': true,
      }));
    } catch (e) {
      // Log failed load booking
      await logEvent('load_booked', parameters: _convertParameters({
        'load_id': loadId,
        'success': false,
        'error': e.toString(),
      }));
      await recordError(e, StackTrace.current, reason: 'Failed to mark load as booked');
      rethrow;
    }
  }

  // Unmark load as booked
  static Future<void> unmarkLoadAsBooked(
    String shipperUid,
    String loadId,
  ) async {
    try {
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .update({
        'isBooked': false,
        'status': 'active', // Restore status to active
        'bookedAt': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to unmark load as booked');
      rethrow;
    }
  }
}
