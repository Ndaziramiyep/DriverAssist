import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:driver_assist/models/user_model.dart';
import 'dart:io';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
            
        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Create new user document
          final newUser = UserModel(
            id: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? '',
            email: userCredential.user!.email ?? '',
            phoneNumber: userCredential.user!.phoneNumber,
            profileImage: userCredential.user!.photoURL,
            emergencyContacts: [],
            preferences: {},
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUser.toMap());

          return newUser;
        }

        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(name);

        // Create user document
        final newUser = UserModel(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          phoneNumber: userCredential.user!.phoneNumber,
          profileImage: userCredential.user!.photoURL,
          emergencyContacts: [],
          preferences: {},
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());
      }
      
      // Return the UserCredential
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final storageRef = _storage.ref().child('profile_images/${user.uid}');
      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Update user profile in Firebase Auth
      await user.updatePhotoURL(downloadUrl);
      
      // Update Firestore user document
      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String displayName,
    String? phoneNumber,
    String? address,
    File? profileImage,
  }) async {
    String? profileImageUrl;
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    bool imageUploadFailed = false;
    String? imageErrorMsg;
    if (profileImage != null) {
      try {
        profileImageUrl = await uploadProfileImage(profileImage);
      } catch (e) {
        imageUploadFailed = true;
        imageErrorMsg = 'There was a problem uploading your profile image. Please try again with a different image.';
      }
    }
    // Update Firebase Auth profile
    await user.updateDisplayName(displayName);
    if (profileImageUrl != null) {
      await user.updatePhotoURL(profileImageUrl);
    }
    await user.reload();
    // Update Firestore user document
    final updates = <String, dynamic>{
      'name': displayName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      if (profileImageUrl != null) 'profileImage': profileImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('users').doc(user.uid).set(
      updates,
      SetOptions(merge: true),
    ).timeout(const Duration(seconds: 10));
    notifyListeners();
    if (imageUploadFailed) {
      throw Exception(imageErrorMsg);
    }
  }

  Future<void> addEmergencyContact(String userId, String contact) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'emergencyContacts': FieldValue.arrayUnion([contact]),
      });
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeEmergencyContact(String userId, String contact) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'emergencyContacts': FieldValue.arrayRemove([contact]),
      });
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}