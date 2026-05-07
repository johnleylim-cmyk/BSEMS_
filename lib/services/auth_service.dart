import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import '../models/user_model.dart';

/// Firebase Authentication service — handles registration, login, logout.
/// First registered user automatically becomes Admin.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Register a new user. First user in the system becomes Admin.
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Check if this is the first user → make admin
    final usersSnapshot = await _db
        .collection(AppConstants.usersCollection)
        .limit(1)
        .get();
    final role =
        usersSnapshot.docs.isEmpty ? UserRole.admin : UserRole.viewer;

    final user = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role,
      createdAt: DateTime.now(),
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(user.toMap());

    return user;
  }

  /// Sign in with email/password.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();

    if (!doc.exists) {
      throw Exception('User profile not found');
    }

    return UserModel.fromMap(doc.data()!, uid);
  }

  /// Get current user's profile from Firestore.
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, user.uid);
  }

  /// Update user profile.
  Future<void> updateProfile(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update({
      'displayName': user.displayName,
      'role': user.role.name,
      'photoUrl': user.photoUrl,
    });
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get all users (admin only).
  Future<List<UserModel>> getAllUsers() async {
    final snapshot =
        await _db.collection(AppConstants.usersCollection).get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Send a password-reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update a user's role (admin only).
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'role': role.name});
  }

  /// Mark the current moment as the last time the user viewed announcements.
  Future<void> updateLastSeenAnnouncements(String uid) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'lastSeenAnnouncementsAt': FieldValue.serverTimestamp()});
  }
}
