// lib/screens/form_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:exam_5_128/models/app_user.dart';
import 'package:exam_5_128/models/incident.dart';

class FormScreen extends StatefulWidget {
  final AppUser currentUser;
  const FormScreen({super.key, required this.currentUser});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _ticketNo = '';
  String _attackVector = '';
  String _investigatorEmail = '';
  double _cvssScore = 0;
  int _affectedEndpoints = 0;
  bool _isSaving = false;

  final _incidentCollection =
      FirebaseFirestore.instance.collection('incidents');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final incident = Incident(
        ticketNo: _ticketNo,
        attackVector: _attackVector,
        investigatorEmail: _investigatorEmail,
        cvssScore: _cvssScore,
        affectedEndpoints: _affectedEndpoints,
      );

      await _incidentCollection.add({
        ...incident.toMap(),
        // เก็บเจ้าของเคส เพื่อให้แต่ละบัญชีเห็นเฉพาะข้อมูลของตัวเอง
        'ownerEmail': widget.currentUser.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _formKey.currentState!.reset();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          content: const Text('บันทึกเหตุการณ์สำเร็จ'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          content: Text('บันทึกไม่สำเร็จ: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _decoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: _decoration(
                'หมายเลขบัตรแจ้งเหตุ (Ticket No.)',
                'เช่น SOC-INC-881',
                Icons.confirmation_number_outlined,
              ),
              validator: RequiredValidator(
                      errorText: 'กรุณาป้อนหมายเลขบัตรแจ้งเหตุ')
                  .call,
              onSaved: (value) => _ticketNo = value!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: _decoration(
                'ประเภทภัยคุกคาม (Attack Vector)',
                'เช่น Ransomware, DDoS, Phishing',
                Icons.bug_report_outlined,
              ),
              validator:
                  RequiredValidator(errorText: 'กรุณาป้อนประเภทภัยคุกคาม')
                      .call,
              onSaved: (value) => _attackVector = value!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              decoration: _decoration(
                'อีเมลนักวิเคราะห์ SOC (Investigator Email)',
                'name@soc.com',
                Icons.alternate_email,
              ),
              validator: MultiValidator([
                RequiredValidator(errorText: 'กรุณาป้อนอีเมล'),
                EmailValidator(errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
              ]).call,
              onSaved: (value) => _investigatorEmail = value!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration(
                'คะแนนความเสี่ยง CVSS Score (0.0 - 10.0)',
                'เช่น 7.5',
                Icons.speed,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาป้อนคะแนน CVSS';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed < 0 || parsed > 10) {
                  return 'คะแนนต้องอยู่ระหว่าง 0.0 - 10.0';
                }
                return null;
              },
              onSaved: (value) => _cvssScore = double.parse(value!.trim()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: _decoration(
                'จำนวนระบบที่ได้รับผลกระทบ (Affected Endpoints)',
                'เช่น 12',
                Icons.computer,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาป้อนจำนวนระบบที่ได้รับผลกระทบ';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'กรุณาป้อนตัวเลขเท่านั้น';
                }
                return null;
              },
              onSaved: (value) =>
                  _affectedEndpoints = int.parse(value!.trim()),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('บันทึกเหตุการณ์',
                  style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}