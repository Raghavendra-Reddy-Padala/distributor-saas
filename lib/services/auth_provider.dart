import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  String? _distributorId;
  String? _distributorName;
  bool _isLoading = true; 
  String? _errorMessage;

  // Public Getters
  User? get user => _user;
  String? get distributorId => _distributorId;
  String? get distributorName => _distributorName;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Checks if user is logged in AND is a valid, fetched distributor
  bool get isLoggedIn => _user != null && _distributorId != null;

  AuthProvider() {
    // Listen to authentication changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Called whenever the user signs in or out
  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _user = null;
      _distributorId = null;
      _distributorName = null;
      _isLoading = false;
      notifyListeners();
    } else {
      _user = user;
      // User is logged in, now verify they are a distributor
      await _fetchDistributorData(user.uid);
    }
  }

  /// Fetches distributor-specific data from Firestore
  Future<void> _fetchDistributorData(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        
        // CRITICAL: Check role and distributorId
        if (data['role'] == 'distributor' && data['distributorId'] != null) {
          _distributorId = data['distributorId'];
          
          // Now, fetch the distributor's name for the welcome message
          final distDoc = await _db.collection('distributors').doc(_distributorId!).get();
          
          if (distDoc.exists) {
            _distributorName = (distDoc.data() as Map<String, dynamic>)['name'];
          } else {
            // User points to a distributor that doesn't exist
            throw Exception('Distributor record not found.');
          }
        } else {
          // User is not a distributor
          throw Exception('Access denied: This account is not a distributor account.');
        }
      } else {
        // No user record found
        throw Exception('User data not found in database.');
      }
    } catch (e) {
      _errorMessage = e.toString();
      // If any error occurs, log the user out
      await _auth.signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return true;
    } on FirebaseAuthException catch (e) {
      // Detailed error handling
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No account found with this email address.';
          break;
        case 'wrong-password':
          _errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address format.';
          break;
        case 'user-disabled':
          _errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          _errorMessage = 'Invalid email or password. Please check your credentials.';
          break;
        case 'network-request-failed':
          _errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          _errorMessage = e.message ?? 'Login failed. Please try again.';
          debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      debugPrint('Sign in error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _auth.signOut();
    // Auth state listener (_onAuthStateChanged) will clear the state
  }

  /// Send Password Reset Email
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address format.';
          break;
        default:
          _errorMessage = e.message ?? 'Error sending reset email.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}