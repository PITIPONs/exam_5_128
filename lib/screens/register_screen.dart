// lib/screens/register_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

// สมัครสมาชิก: บันทึกผู้ใช้ลง collection "users" ใน Firestore โดยตรง
// (ตรงกับระบบ login ที่ค้นหาอีเมลจาก collection "users" ไม่ใช้ Firebase Auth)
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

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

    try {
      final users = FirebaseFirestore.instance.collection('users');

      // 1) ตรวจว่าอีเมลนี้ถูกใช้แล้วหรือยัง
      final existing = await users
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 15));

      if (existing.docs.isNotEmpty) {
        setState(() {
          _errorText = 'อีเมลนี้ถูกใช้งานแล้ว';
          _isLoading = false;
        });
        return;
      }

      // 2) บันทึกผู้ใช้ใหม่ (role เริ่มต้นเป็น operator เสมอ)
      await users.add({
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'operator',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // กลับไปหน้า login
    } on TimeoutException {
      setState(() {
        _errorText =
            'เชื่อมต่อ Firestore ไม่สำเร็จ (หมดเวลา) กรุณาตรวจสอบอินเทอร์เน็ต';
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorText = e.code == 'permission-denied'
            ? 'ไม่มีสิทธิ์เขียนข้อมูล กรุณาตรวจสอบ Rules ของ Firestore'
            : 'เกิดข้อผิดพลาด (${e.code}): ${e.message}';
        _isLoading = false;
      });
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
                  textInputAction: TextInputAction.done,
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