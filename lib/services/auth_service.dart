import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? '340096103166-mr9aa7aonb7g9adcnd3ievids77685f6.apps.googleusercontent.com'
        : null,
  );

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

  Future<UserCredential?> signInWithGoogle() async {    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    final userCredential = await _auth.signInWithCredential(oauthCredential);
    // Apple only sends the name on first sign-in — persist it if present
    final fullName = appleCredential.givenName != null
        ? '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim()
        : null;
    if (fullName != null && fullName.isNotEmpty &&
        userCredential.user?.displayName == null) {
      await userCredential.user?.updateDisplayName(fullName);
    }
    return userCredential;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
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

    // 5. Sign out social providers
    await _googleSignIn.signOut();
  }
}
