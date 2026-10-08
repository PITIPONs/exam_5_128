// lib/models/app_user.dart
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // "Admin" หรือ "Operator"

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'Admin';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Operator',
    );
  }
}