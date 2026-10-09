// lib/screens/register_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

// สมัครสมาชิก: สร้างบัญชีใน Firebase Authentication
// แล้วบันทึกข้อมูลผู้ใช้ลง collection "users" ใน Firestore
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    User? createdUser;

    try {
      // 1) สร้างบัญชีใน Firebase Authentication
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      createdUser = cred.user;

      // 2) บันทึกข้อมูลผู้ใช้ลง Firestore (role เริ่มต้นเป็น operator เสมอ)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser!.uid)
          .set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'operator',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 20));

      // 3) ออกจากระบบ เพื่อให้ผู้ใช้ล็อกอินเองที่หน้า login
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // กลับไปหน้า login
    } on TimeoutException {
      await _rollback(createdUser);
      if (!mounted) return;
      setState(() {
        _errorText = 'เชื่อมต่อไม่สำเร็จ (หมดเวลา) กรุณาตรวจสอบอินเทอร์เน็ต';
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'อีเมลนี้ถูกใช้งานแล้ว';
          break;
        case 'invalid-email':
          msg = 'รูปแบบอีเมลไม่ถูกต้อง';
          break;
        case 'weak-password':
          msg = 'รหัสผ่านง่ายเกินไป (อย่างน้อย 6 ตัวอักษร)';
          break;
        case 'network-request-failed':
          msg = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
          break;
        case 'operation-not-allowed':
          msg = 'ยังไม่ได้เปิดใช้การสมัครด้วยอีเมล/รหัสผ่านใน Firebase';
          break;
        default:
          msg = 'เกิดข้อผิดพลาด (${e.code})';
      }
      if (!mounted) return;
      setState(() {
        _errorText = msg;
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      // ข้อผิดพลาดจาก Firestore: ลบบัญชี Auth ที่เพิ่งสร้าง เพื่อไม่ให้ค้างครึ่งทาง
      await _rollback(createdUser);
      if (!mounted) return;
      setState(() {
        _errorText = e.code == 'permission-denied'
            ? 'ไม่มีสิทธิ์เขียนข้อมูล กรุณาตรวจสอบ Rules ของ Firestore'
            : 'เกิดข้อผิดพลาด (${e.code}): ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      await _rollback(createdUser);
      if (!mounted) return;
      setState(() {
        _errorText = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _rollback(User? user) async {
    try {
      await user?.delete();
    } catch (_) {
      // ไม่ต้องทำอะไรต่อ
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOCAlert - สมัครสมาชิก'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add_alt_1,
                    size: 70, color: Colors.redAccent),
                const SizedBox(height: 10),
                const Text(
                  'สร้างบัญชีผู้ใช้ใหม่',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-นามสกุล',
                    border: OutlineInputBorder(),
                  ),
                  validator: RequiredValidator(errorText: 'กรุณาป้อนชื่อ').call,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'อีเมลผู้ใช้งาน',
                    border: OutlineInputBorder(),
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'กรุณาป้อนอีเมล'),
                    EmailValidator(errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
                  ]).call,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    border: OutlineInputBorder(),
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'กรุณาป้อนเบอร์โทรศัพท์'),
                    PatternValidator(r'^[0-9]{9,10}$',
                        errorText: 'เบอร์โทรต้องเป็นตัวเลข 9-10 หลัก'),
                  ]).call,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน (อย่างน้อย 6 ตัวอักษร)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'กรุณาป้อนรหัสผ่าน'),
                    MinLengthValidator(6,
                        errorText: 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'),
                  ]).call,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'ยืนยันรหัสผ่าน',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณายืนยันรหัสผ่าน';
                    }
                    if (value != _passwordController.text) {
                      return 'รหัสผ่านไม่ตรงกัน';
                    }
                    return null;
                  },
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
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('สมัครสมาชิก',
                          style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}