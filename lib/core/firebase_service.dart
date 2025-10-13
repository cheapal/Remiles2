import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/user_model.dart';
import '../models/shipper_model.dart';
import '../models/carrier_model.dart';

/// Firebase service class to handle all Firebase operations
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  // static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
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
  // static FirebaseAnalytics get analytics => _analytics;
  // static Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
  //   await _analytics.logEvent(name: name, parameters: parameters);
  // }

  // Crashlytics methods
  static FirebaseCrashlytics get crashlytics => _crashlytics;
  static Future<void> recordError(dynamic exception, StackTrace? stackTrace, {String? reason}) async {
    await _crashlytics.recordError(exception, stackTrace, reason: reason);
  }

  // User management methods
  static Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Sign in failed');
      rethrow;
    }
  }

  static Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'User creation failed');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
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
        await createShipper(shipper);
      }

      return userCredential;
    } catch (e) {
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
      }

      return userCredential;
    } catch (e) {
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

      return await getUserByRole(user.uid, role);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get current user data failed');
      rethrow;
    }
  }
}
