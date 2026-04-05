import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/firestore_paths.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Stream of auth state changes ──────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Get current Firebase user ─────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Register with email & password ────────────────────────────────────────
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(displayName);

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName,
        role: role,
        status: role == 'seller' ? 'pending' : 'active',
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .doc(FirestorePaths.userDoc(user.uid))
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ── Login with email & password ───────────────────────────────────────────
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return await _getUserFromFirestore(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ── Get any user by UID from Firestore ────────────────────────────────────
  Future<UserModel> getUserById(String uid) async {
    final doc = await _firestore.doc(FirestorePaths.userDoc(uid)).get();
    if (!doc.exists) throw Exception('User record not found');
    return UserModel.fromMap(doc.data()!, uid);
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<UserModel> signInWithGoogle({String role = 'customer'}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign-In cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Check if user already exists in Firestore
      final doc = await _firestore.doc(FirestorePaths.userDoc(user.uid)).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, user.uid);
      }

      // First time Google login — create Firestore record
      final userModel = UserModel(
        uid: user.uid,
        email: user.email!,
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        role: role,
        status: 'active',
        createdAt: DateTime.now(),
      );

      await _firestore
          .doc(FirestorePaths.userDoc(user.uid))
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Fetch user from Firestore ─────────────────────────────────────────────
  Future<UserModel> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.doc(FirestorePaths.userDoc(uid)).get();
    if (!doc.exists) throw Exception('User record not found');
    return UserModel.fromMap(doc.data()!, uid);
  }

  // ── Auth error handler ────────────────────────────────────────────────────
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}