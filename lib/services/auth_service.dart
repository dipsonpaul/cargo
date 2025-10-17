import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        UserModel? userModel = await getUserById(result.user!.uid);
        if (userModel == null) {
          // Auto-provision Firestore profile for authenticated user (first login)
          final String userEmail = result.user!.email ?? email;
          final String derivedName = userEmail.split('@').first;

          // Map known demo accounts to roles; default to customer
          UserRole inferredRole;
          switch (userEmail.toLowerCase()) {
            case 'admin@cargo.com':
              inferredRole = UserRole.admin;
              break;
            case 'driver@cargo.com':
              inferredRole = UserRole.driver;
              break;
            case 'customer@cargo.com':
              inferredRole = UserRole.customer;
              break;
            default:
              inferredRole = UserRole.customer;
          }

          final UserModel newUser = UserModel(
            id: result.user!.uid,
            email: userEmail,
            name: derivedName,
            phone: '',
            role: inferredRole,
            createdAt: DateTime.now(),
            isFirstLogin: true,
          );

          await _firestore.collection('users').doc(result.user!.uid).set(
            newUser.toFirestore(),
          );

          userModel = newUser;
        }

        // Update last login
        await _updateLastLogin(result.user!.uid);
        
        // Save user data to local storage
        await _saveUserToLocal(userModel);
        
        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearLocalUser();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Re-authenticate user
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        
        // Update password
        await user.updatePassword(newPassword);
        
        // Update first login flag
        await _firestore.collection('users').doc(user.uid).update({
          'isFirstLogin': false,
        });
      }
    } catch (e) {
      throw Exception('Password change failed: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Create user account (Admin only)
  Future<UserModel> createUserAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    try {
      // Create Firebase Auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Create user document in Firestore
        UserModel userModel = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
          isFirstLogin: true,
        );

        await _firestore.collection('users').doc(result.user!.uid).set(
          userModel.toFirestore(),
        );

        return userModel;
      }
      throw Exception('Failed to create user account');
    } catch (e) {
      throw Exception('User creation failed: $e');
    }
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete from Firebase Auth (Admin only)
      // Note: This requires Admin SDK or special permissions
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Get all users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.toString().split('.').last)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // Get local user data
  Future<UserModel?> getLocalUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        // Parse user data from local storage
        // This is a simplified version - you might want to use a proper JSON serialization
        return null; // Implement JSON parsing here
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save user to local storage
  Future<void> _saveUserToLocal(UserModel user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Save user data to local storage
      // This is a simplified version - you might want to use proper JSON serialization
      await prefs.setString('current_user', user.id);
    } catch (e) {
      // Handle error silently
    }
  }

  // Clear local user data
  Future<void> _clearLocalUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      // Handle error silently
    }
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Handle error silently
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Check if user exists
  Future<bool> userExists(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
