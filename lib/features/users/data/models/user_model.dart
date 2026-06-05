import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullname;
  final String role;
  final String username;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullname,
    required this.role,
    required this.username,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: (map['email'] ?? '').toString().trim(),
      fullname: (map['fullname'] ?? '').toString().trim(),
      role: (map['role'] ?? '').toString().trim(),
      username: (map['username'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullname': fullname,
      'role': role,
      'username': username,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullname,
    String? role,
    String? username,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullname: fullname ?? this.fullname,
      role: role ?? this.role,
      username: username ?? this.username,
    );
  }

  @override
  List<Object?> get props => [id, email, fullname, role, username];
}
