// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Available clubs
  static const List<String> availableClubs = [
    'Springfield Rifle Club',
    'Oak Valley Shooting Range',
    'Mountain View Gun Club',
    'Riverside Marksmanship Association',
    'Metro Target Sports',
  ];

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Register new user with email and password
  Future<UserProfile> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required List<String> clubs,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Create user profile
      final userProfile = UserProfile(
        uid: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        clubs: clubs,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Store user profile in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userProfile.toJson());

      return userProfile;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Sign in with email and password
  Future<UserProfile> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }

      // Get user profile from Firestore
      final userProfile = await getUserProfile(user.uid);

      // Update last login time
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      return userProfile;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Get user profile from Firestore
  Future<UserProfile> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw Exception('User profile not found');
      }

      return UserProfile.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .update(profile.toJson());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Delete user profile from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user from Firebase Auth
      await user.delete();

      // Clear any stored passcode
      await clearPasscode();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'Please log in again before deleting your account for security reasons.');
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Re-authenticate user (needed for sensitive operations like delete account)
  Future<void> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============ PASSCODE MANAGEMENT ============

  /// Set up passcode for local authentication
  Future<void> setPasscode(String passcode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _secureStorage.write(
        key: 'user_passcode_${user.uid}',
        value: passcode,
      );
    } catch (e) {
      throw Exception('Failed to set passcode: $e');
    }
  }

  /// Verify passcode
  Future<bool> verifyPasscode(String passcode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final storedPasscode = await _secureStorage.read(
        key: 'user_passcode_${user.uid}',
      );

      return storedPasscode == passcode;
    } catch (e) {
      return false;
    }
  }

  /// Check if passcode is set
  Future<bool> hasPasscode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final passcode = await _secureStorage.read(
        key: 'user_passcode_${user.uid}',
      );

      return passcode != null && passcode.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clear passcode
  Future<void> clearPasscode() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _secureStorage.delete(key: 'user_passcode_${user.uid}');
      }
    } catch (e) {
      // Ignore errors when clearing passcode
    }
  }

  // ============ BIOMETRIC AUTHENTICATION ============

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric is enabled for user
  Future<bool> isBiometricEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final enabled = await _secureStorage.read(
        key: 'biometric_enabled_${user.uid}',
      );

      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _secureStorage.write(
        key: 'biometric_enabled_${user.uid}',
        value: enabled.toString(),
      );
    } catch (e) {
      throw Exception('Failed to set biometric preference: $e');
    }
  }

  // ============ ERROR HANDLING ============

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'Please log in again to continue.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
