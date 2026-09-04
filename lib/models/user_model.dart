enum UserRole { admin, cashier, user }

class UserModel {
  final String id;
  final String name;
  final String username;
  final UserRole role;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      role: (map['role']?.toString().toLowerCase() == 'admin')
          ? UserRole.admin
          : (map['role']?.toString().toLowerCase() == 'user')
              ? UserRole.user
              : UserRole.cashier,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role.name,
    };
  }
}
