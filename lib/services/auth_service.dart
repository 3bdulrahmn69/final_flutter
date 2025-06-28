import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Google Sign-In will be initialized when needed
  GoogleSignIn? _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential?> registerWithEmailPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    String phone,
    String city,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document with all details
      await _createUserDocument(
        result.user!,
        '$firstName $lastName',
        email,
        null,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phone,
        city: city,
      );

      return result;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Initialize Google Sign-In lazily
      _googleSignIn ??= GoogleSignIn(scopes: ['email', 'profile']);

      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      // Create user document if new user
      await _createUserDocument(
        result.user!,
        googleUser.displayName ?? 'User',
        googleUser.email,
        googleUser.photoUrl,
      );

      return result;
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }

  // Facebook Sign In
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(
          accessToken.tokenString,
        );

        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        // Get Facebook user data
        final userData = await FacebookAuth.instance.getUserData();

        // Create user document if new user
        await _createUserDocument(
          userCredential.user!,
          userData['name'] ?? 'User',
          userCredential.user!.email ?? '',
          userData['picture']['data']['url'],
        );

        return userCredential;
      }
    } catch (e) {
      print('Facebook sign in error: $e');
    }
    return null;
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user,
    String displayName,
    String email,
    String? photoUrl, {
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? city,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          profilePicture: photoUrl,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          city: city,
          createdAt: DateTime.now(),
        );

        await userDoc.set(userModel.toMap());
      }
    } catch (e) {
      print('Error creating user document: $e');
      // Don't throw error for offline issues, continue with auth
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }
}
