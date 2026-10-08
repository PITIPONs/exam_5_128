// lib/screens/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:exam_5_128/models/app_user.dart';
import 'package:exam_5_128/screens/home_screen.dart';
import 'package:exam_5_128/screens/register_screen.dart';

// จำลองบัญชีผู้ใช้: กรอกอีเมล แล้วค้นหา role จาก collection "users"
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final email = _emailController.text.trim();

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _errorText = 'ไม่พบบัญชีผู้ใช้นี้ในระบบ';
          _isLoading = false;
        });
        return;
      }

      final doc = query.docs.first;
      final user = AppUser.fromMap(doc.id, doc.data());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(currentUser: user)),
      );
    } catch (e) {
      setState(() {
        _errorText = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOCAlert - เข้าสู่ระบบ'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield, size: 80, color: Colors.redAccent),
              const SizedBox(height: 10),
              const Text(
                'SOC Alert Dispatch',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'อีเมลผู้ใช้งาน',
                  hintText: 'admin@test.com หรือ operator@test.com',
                  border: OutlineInputBorder(),
                ),
                validator: MultiValidator([
                  RequiredValidator(errorText: 'กรุณาป้อนอีเมล'),
                  EmailValidator(errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
                ]).call,
              ),
              const SizedBox(height: 16),
              if (_errorText != null)
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('เข้าสู่ระบบ',
                        style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                child: const Text(
                  'ยังไม่มีบัญชี? สมัครสมาชิก',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}