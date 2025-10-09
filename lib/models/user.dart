import 'package:konfipass/models/constants.dart';

enum UserRole {
  admin(1),
  user(2);

  final int id;
  const UserRole(this.id);

  static UserRole fromId(int id) {
    return UserRole.values.firstWhere(
          (role) => role.id == id,
      orElse: () => UserRole.user,
    );
  }
}

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final UserRole role;
  final String? profileImgPath;
  final String uuid;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.profileImgPath,
    required this.uuid,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    username: json['username'] as String,
    role: UserRole.fromId(json['role'] as int),
    profileImgPath: json['profileImgPath'] != null
        ? "$serverUrl/${json['profileImgPath']}"
        : null,
    uuid: json['uuid'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'username': username,
    'role': role.id,
    'profileImgPath': profileImgPath,
    'uuid': uuid,
  };

  User copyWith({
    int? id,
    String? uuid,
    String? firstName,
    String? lastName,
    String? username,
    String? profileImgPath,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      profileImgPath: profileImgPath ?? this.profileImgPath,
      role: role ?? this.role,
    );
  }
}
