import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart'; // Add this import for PlatformException
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';  // Fix import

class AuthService {
  AuthService();  // Remove const constructor
  
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();  // Initialize GoogleSignIn without const

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Enhanced sign out to clear all sessions
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear stored credentials
      
      // Clear Google Sign In
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.disconnect();
        await _googleSignIn.signOut();
      }
      
      // Clear Firebase Auth
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _db.collection('usernames').doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  Future<bool> updateUsername(String username) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final batch = _db.batch();
    final userDoc = _db.collection('users').doc(user.uid);
    final usernameDoc = _db.collection('usernames').doc(username.toLowerCase());

    try {
      // Check if username is taken
      if (!await isUsernameAvailable(username)) {
        return false;
      }

      // Get current username if exists
      final userData = await userDoc.get();
      final oldUsername = userData.data()?['username'] as String?;

      if (oldUsername != null) {
        // Delete old username reservation
        batch.delete(_db.collection('usernames').doc(oldUsername.toLowerCase()));
      }

      // Reserve new username
      batch.set(usernameDoc, {
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update user profile
      batch.update(userDoc, {
        'username': username,
        'updatedAt': FieldValue.serverTimestamp(),
        'needsProfileSetup': false,  // Add this line
      });

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getUsername() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['username'] as String?;
  }

  Future<String?> getAvatarPath() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    final filename = doc.data()?['avatarPath'] as String?;
    if (filename == null) return null;
    return 'assets/avatars/$filename';  // Return full asset path
  }

  Future<bool> updateAvatar(String avatarId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _db.collection('users').doc(user.uid).update({
        'avatarPath': 'avatar$avatarId.png',  // Store just the filename
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // First ensure we're signed out completely
      await signOut();

      if (kIsWeb) {
        // Create a new provider
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Add persistence
        await _auth.setPersistence(Persistence.LOCAL);
        
        googleProvider.setCustomParameters({
          'prompt': 'select_account', // Force account selection
          'client_id': '977857362801-rs8b2k59qbudfjuba9dmr4bticab8n06.apps.googleusercontent.com'
        });
        
        // Add these scopes
        googleProvider.addScope('https://www.googleapis.com/auth/userinfo.email');
        googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');
        
        // Try popup first
        try {
          final userCredential = await _auth.signInWithPopup(googleProvider);
          if (userCredential.user != null) {
            print('Successfully signed in as: ${userCredential.user?.email}');
            await _handleSignInSuccess(userCredential);
            return userCredential;
          }
          return null;
        } catch (e) {
          print('Popup sign in failed, trying redirect: $e');
          await _auth.signInWithRedirect(googleProvider);
          return null;
        }
      } else {
        // Mobile implementation
        await _auth.setPersistence(Persistence.LOCAL);
        
        // Force account selection
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          print('Google Sign In was cancelled by user');
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          print('Could not obtain auth tokens');
          return null;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          print('Successfully signed in as: ${userCredential.user?.email}');
          await _db.collection('users').doc(userCredential.user!.uid).set({
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName,
            'photoURL': userCredential.user!.photoURL,
            'lastLogin': FieldValue.serverTimestamp(),
            'provider': 'google',
          }, SetOptions(merge: true));
        }

        return userCredential;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      if (e is FirebaseAuthException) {
        print('Firebase Auth Error Code: ${e.code}');
        print('Firebase Auth Error Message: ${e.message}');
      } else if (e is PlatformException) {
        print('Platform Error Code: ${e.code}');
        print('Platform Error Message: ${e.message}');
      }
      // Ensure clean state on error
      await signOut();
      return null;
    }
  }

  Future<void> _handleSignInSuccess(UserCredential credential) async {
    if (credential.user != null) {
      final userDoc = _db.collection('users').doc(credential.user!.uid);
      final userData = await userDoc.get();
      
      // Create regular timestamp for array
      final now = Timestamp.now();
      
      if (!userData.exists) {
        // New user
        await userDoc.set({
          'email': credential.user!.email,
          'displayName': credential.user!.displayName,
          'photoURL': credential.user!.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
          'provider': 'google',
          'needsProfileSetup': true,  // Add this flag
          'createdAt': FieldValue.serverTimestamp(),
          'deviceSignIns': [
            {
              'timestamp': now,  // Use regular timestamp here
              'platform': kIsWeb ? 'web' : 'mobile',
              'deviceId': await _getDeviceId(),
            }
          ],
        });
      } else {
        // Existing user - update login history
        await userDoc.update({
          'lastLogin': FieldValue.serverTimestamp(),
          'deviceSignIns': FieldValue.arrayUnion([
            {
              'timestamp': now,  // Use regular timestamp here
              'platform': kIsWeb ? 'web' : 'mobile',
              'deviceId': await _getDeviceId(),
            }
          ]),
        });
      }
    }
  }

  // Helper method to get unique device identifier
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
    }
    
    return deviceId;
  }

  // Add these methods for account management
  Future<List<UserInfo>> getLinkedProviders() async {
    final user = _auth.currentUser;
    return user?.providerData ?? [];
  }

  Future<void> linkGoogleAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        await user.linkWithPopup(googleProvider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.linkWithCredential(credential);
      }
    } catch (e) {
      print('Error linking Google account: $e');
      rethrow;
    }
  }

  Future<void> unlinkProvider(String providerId) async {
    try {
      await _auth.currentUser?.unlink(providerId);
    } catch (e) {
      print('Error unlinking provider: $e');
      rethrow;
    }
  }

  Future<bool> needsProfileSetup() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();
    
    return data?['needsProfileSetup'] == true;
  }

  Future<bool> isProfileComplete() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();
    
    // Check if username and avatar are set
    return data != null && 
           data['username'] != null && 
           data['avatarPath'] != null;
  }
}
