// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:exam_5_128/models/app_user.dart';
import 'package:exam_5_128/screens/form_screen.dart';
import 'package:exam_5_128/screens/display_screen.dart';
import 'package:exam_5_128/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppUser currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('SOCAlert (${currentUser.role})'),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.add_alert), text: 'บันทึกเหตุการณ์'),
              Tab(icon: Icon(Icons.list_alt), text: 'วอร์รูม'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FormScreen(currentUser: currentUser),
            DisplayScreen(currentUser: currentUser),
          ],
        ),
      ),
    );
  }
}