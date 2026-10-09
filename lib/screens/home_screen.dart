// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:exam_5_128/models/app_user.dart';
import 'package:exam_5_128/screens/form_screen.dart';
import 'package:exam_5_128/screens/display_screen.dart';
import 'package:exam_5_128/screens/login_screen.dart';
import 'package:exam_5_128/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final AppUser currentUser;
  const HomeScreen({super.key, required this.currentUser});

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout, color: AppColors.accent),
        title: const Text('ออกจากระบบ'),
        content: const Text('ต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final source =
        currentUser.name.isNotEmpty ? currentUser.name : currentUser.email;
    final initial = source.isNotEmpty ? source[0].toUpperCase() : '?';
    final roleColor =
        currentUser.isAdmin ? AppColors.accent : const Color(0xFF2563EB);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 70,
          titleSpacing: 16,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: roleColor,
                child: Text(
                  initial,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentUser.role,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmSignOut(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            FormScreen(currentUser: currentUser),
            DisplayScreen(currentUser: currentUser),
          ],
        ),
        bottomNavigationBar: Material(
          color: AppColors.navy,
          child: SafeArea(
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.add_alert), text: 'แจ้งเหตุ'),
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'วอร์รูม'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}