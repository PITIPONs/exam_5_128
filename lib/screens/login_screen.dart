// lib/screens/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:exam_5_128/models/app_user.dart';
import 'package:exam_5_128/screens/home_screen.dart';
import 'package:exam_5_128/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fill(String email) {
    setState(() {
      _emailController.text = email;
      _errorText = null;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // 1) ยืนยันตัวตนด้วย Firebase Authentication
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 2) ดึงข้อมูลผู้ใช้ (role ฯลฯ) จาก Firestore
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() {
          _errorText =
              'ไม่พบข้อมูลผู้ใช้ในฐานข้อมูล (Firestore: users)';
          _isLoading = false;
        });
        return;
      }

      final doc = query.docs.first;
      final user = AppUser.fromMap(doc.id, doc.data());

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(currentUser: user)),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
          break;
        case 'invalid-email':
          msg = 'รูปแบบอีเมลไม่ถูกต้อง';
          break;
        case 'user-disabled':
          msg = 'บัญชีนี้ถูกระงับการใช้งาน';
          break;
        case 'too-many-requests':
          msg = 'พยายามเข้าสู่ระบบบ่อยเกินไป กรุณาลองใหม่ภายหลัง';
          break;
        case 'network-request-failed':
          msg = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
          break;
        default:
          msg = 'เกิดข้อผิดพลาด: ${e.code}';
      }
      if (!mounted) return;
      setState(() {
        _errorText = msg;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  // โลโก้แอป: ใช้รูปจาก assets/icon/image.png
  // ถ้าโหลดรูปไม่ได้ จะแสดงไอคอนโล่แทน (ไม่ทำให้แอปพัง)
  Widget _buildLogo() {
    return ClipOval(
      child: Image.asset(
        'assets/icon/image.png',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, size: 48, color: Colors.white),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, AppColors.navyLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 16),
                  const Text(
                    'SOCAlert',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ศูนย์เฝ้าระวังและตอบสนองภัยไซเบอร์',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'กรอกอีเมลและรหัสผ่านเพื่อเข้าใช้งาน',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: appInputDecoration(
                              label: 'อีเมล',
                              hint: 'name@soc.com',
                              icon: Icons.mail_outline,
                            ),
                            validator: MultiValidator([
                              RequiredValidator(errorText: 'กรุณาป้อนอีเมล'),
                              EmailValidator(
                                  errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
                            ]).call,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_isLoading) _login();
                            },
                            decoration: appInputDecoration(
                              label: 'รหัสผ่าน',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: RequiredValidator(
                                    errorText: 'กรุณาป้อนรหัสผ่าน')
                                .call,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'บัญชีทดสอบ (แตะเพื่อเติมอีเมลอัตโนมัติ)',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(
                                    Icons.admin_panel_settings,
                                    size: 18),
                                label: const Text('Admin'),
                                onPressed: () => _fill('admin@test.com'),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.person, size: 18),
                                label: const Text('Operator'),
                                onPressed: () => _fill('operator@test.com'),
                              ),
                            ],
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.critical, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorText!,
                                      style: const TextStyle(
                                          color: AppColors.critical),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}