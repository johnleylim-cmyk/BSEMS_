import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums.dart';

/// User profile model stored in Firestore.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? photoUrl;
  final DateTime? lastSeenAnnouncementsAt;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.lastSeenAnnouncementsAt,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.viewer,
      ),
      photoUrl: map['photoUrl'],
      lastSeenAnnouncementsAt:
          (map['lastSeenAnnouncementsAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? displayName,
    UserRole? role,
    String? photoUrl,
    DateTime? lastSeenAnnouncementsAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSeenAnnouncementsAt:
          lastSeenAnnouncementsAt ?? this.lastSeenAnnouncementsAt,
      createdAt: createdAt,
    );
  }
}
