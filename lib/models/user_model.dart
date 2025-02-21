import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromFirebase(UserCredential credential) {
    return UserModel(
      uid: credential.user?.uid ?? '',
      email: credential.user?.email ?? '',
      name: credential.user?.displayName ?? '',
      createdAt: DateTime.now(),
    );
  }
}
