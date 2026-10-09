// lib/models/app_user.dart
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // เก็บได้ทั้ง "admin"/"Admin" และ "operator"/"Operator"

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  // ไม่สนตัวพิมพ์เล็ก/ใหญ่ เพื่อให้ตรงกับข้อมูลใน Firestore
  bool get isAdmin => role.trim().toLowerCase() == 'admin';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'operator').toString(),
    );
  }
}