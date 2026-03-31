import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role; // 'customer' | 'seller' | 'designer' | 'admin'
  final String status; // 'active' | 'pending' | 'banned'
  final DateTime createdAt;
  final String? fcmToken;
  final List<String> followedShops;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.status,
    required this.createdAt,
    this.fcmToken,
    this.followedShops = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      fcmToken: map['fcmToken'] as String?,
      followedShops: List<String>.from(map['followedShops'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'role': role,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'fcmToken': fcmToken,
    'followedShops': followedShops,
  };

  @override
  List<Object?> get props => [uid, email, role, status];
}