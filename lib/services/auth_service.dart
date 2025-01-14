import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  const AuthService();  // Keep constructor const
  
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

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

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
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
}
