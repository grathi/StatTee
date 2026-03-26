import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(
      String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.updateDisplayName(name);
    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Deletes all user data from Firestore then removes the Firebase Auth account.
  /// Throws [FirebaseAuthException] with code 'requires-recent-login' if
  /// re-authentication is needed — the caller should handle that case.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final db = FirebaseFirestore.instance;

    // 1. Delete subcollections under users/{uid}
    for (final sub in ['smartNotifications', 'teeTimes']) {
      final snap = await db.collection('users').doc(uid).collection(sub).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    // 2. Delete the user document
    await db.collection('users').doc(uid).delete();

    // 3. Delete top-level collection documents owned by this user
    for (final col in ['rounds', 'practice_sessions', 'tournaments']) {
      final snap = await db.collection(col).where('userId', isEqualTo: uid).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }

    // 4. Delete the Firebase Auth account (may throw requires-recent-login)
    await user.delete();
  }
}
