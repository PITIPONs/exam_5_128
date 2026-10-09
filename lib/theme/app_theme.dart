// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF0F172A);
  static const Color navyLight = Color(0xFF1E293B);
  static const Color accent = Color(0xFFE53935);
  static const Color background = Color(0xFFF4F6FA);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color critical = Color(0xFFB71C1C);
  static const Color high = Color(0xFFE53935);
  static const Color medium = Color(0xFFF59E0B);
  static const Color low = Color(0xFF16A34A);
}

/// ระดับความรุนแรงตามคะแนน CVSS
String severityLabel(double score) {
  if (score >= 9) return 'Critical';
  if (score >= 7) return 'High';
  if (score >= 4) return 'Medium';
  return 'Low';
}

Color severityColor(double score) {
  if (score >= 9) return AppColors.critical;
  if (score >= 7) return AppColors.high;
  if (score >= 4) return AppColors.medium;
  return AppColors.low;
}

/// สถานะการกักกัน (Containment)
const List<String> kStatusOptions = [
  'Monitoring',
  'Contained',
  'Eradicated',
  'Closed',
];

String statusLabelThai(String status) {
  switch (status) {
    case 'Contained':
      return 'กักกันแล้ว';
    case 'Eradicated':
      return 'กำจัดภัยแล้ว';
    case 'Closed':
      return 'ปิดเคส';
    default:
      return 'กำลังเฝ้าระวัง';
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'Contained':
      return const Color(0xFF2563EB);
    case 'Eradicated':
      return const Color(0xFF7C3AED);
    case 'Closed':
      return const Color(0xFF16A34A);
    default:
      return const Color(0xFFF59E0B);
  }
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
}

InputDecoration appInputDecoration({
  required String label,
  String? hint,
  required IconData icon,
}) {
  final normal = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.border),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.textMuted),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: normal,
    enabledBorder: normal,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 2),
    ),
  );
}

/// ป้ายสีเล็กๆ เช่น "High", "กักกันแล้ว"
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const Pill({super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดแบ่งกลุ่มฟอร์ม มีหัวข้อพร้อมไอคอน
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}