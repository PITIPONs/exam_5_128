// lib/screens/form_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:exam_5_128/models/app_user.dart';
import 'package:exam_5_128/models/incident.dart';
import 'package:exam_5_128/theme/app_theme.dart';

class FormScreen extends StatefulWidget {
  final AppUser currentUser;
  const FormScreen({super.key, required this.currentUser});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _attackController = TextEditingController();

  String _ticketNo = '';
  String _investigatorEmail = '';
  double _cvssScore = 0;
  int _affectedEndpoints = 0;
  double? _previewScore;
  bool _isSaving = false;

  final _incidentCollection =
      FirebaseFirestore.instance.collection('incidents');

  final _attackSuggestions = const [
    'Ransomware',
    'DDoS',
    'Phishing',
    'Malware',
    'SQL Injection',
  ];

  @override
  void dispose() {
    _attackController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final incident = Incident(
        ticketNo: _ticketNo,
        attackVector: _attackController.text.trim(),
        investigatorEmail: _investigatorEmail,
        cvssScore: _cvssScore,
        affectedEndpoints: _affectedEndpoints,
      );

      await _incidentCollection.add({
        ...incident.toMap(),
        'ownerEmail': widget.currentUser.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _formKey.currentState!.reset();
      _attackController.clear();
      setState(() => _previewScore = null);

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

  Widget _legendDot(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewScore;
    final showPreview = preview != null && preview >= 0 && preview <= 10;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'แจ้งเหตุภัยคุกคามใหม่',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'กรอกข้อมูลให้ครบทุกช่อง แล้วกดบันทึกที่ด้านล่าง',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            // ส่วนที่ 1: ข้อมูลเหตุการณ์
            SectionCard(
              title: 'ข้อมูลเหตุการณ์',
              icon: Icons.confirmation_number_outlined,
              children: [
                TextFormField(
                  decoration: appInputDecoration(
                    label: 'หมายเลขบัตรแจ้งเหตุ (Ticket No.)',
                    hint: 'เช่น SOC-INC-881',
                    icon: Icons.tag,
                  ),
                  validator: RequiredValidator(
                          errorText: 'กรุณาป้อนหมายเลขบัตรแจ้งเหตุ')
                      .call,
                  onSaved: (value) => _ticketNo = value!.trim(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _attackController,
                  decoration: appInputDecoration(
                    label: 'ประเภทภัยคุกคาม (Attack Vector)',
                    hint: 'พิมพ์เอง หรือแตะตัวเลือกด้านล่าง',
                    icon: Icons.bug_report_outlined,
                  ),
                  validator: RequiredValidator(
                          errorText: 'กรุณาป้อนประเภทภัยคุกคาม')
                      .call,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  children: _attackSuggestions
                      .map(
                        (s) => ActionChip(
                          label: Text(s),
                          onPressed: () {
                            setState(() => _attackController.text = s);
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ส่วนที่ 2: ผู้รับผิดชอบ
            SectionCard(
              title: 'ผู้รับผิดชอบ',
              icon: Icons.person_outline,
              children: [
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: appInputDecoration(
                    label: 'อีเมลนักวิเคราะห์ SOC',
                    hint: 'name@soc.com',
                    icon: Icons.alternate_email,
                  ),
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'กรุณาป้อนอีเมล'),
                    EmailValidator(errorText: 'รูปแบบอีเมลไม่ถูกต้อง'),
                  ]).call,
                  onSaved: (value) => _investigatorEmail = value!.trim(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ส่วนที่ 3: ความรุนแรง
            SectionCard(
              title: 'ระดับความรุนแรง',
              icon: Icons.speed,
              children: [
                TextFormField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: appInputDecoration(
                    label: 'คะแนน CVSS (0.0 - 10.0)',
                    hint: 'เช่น 7.5',
                    icon: Icons.trending_up,
                  ),
                  onChanged: (value) {
                    setState(() => _previewScore = double.tryParse(value.trim()));
                  },
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
                  onSaved: (value) =>
                      _cvssScore = double.parse(value!.trim()),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _legendDot('Low 0-3.9', AppColors.low),
                    _legendDot('Medium 4-6.9', AppColors.medium),
                    _legendDot('High 7-8.9', AppColors.high),
                    _legendDot('Critical 9-10', AppColors.critical),
                  ],
                ),
                if (showPreview) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('ระดับที่ได้: ',
                          style: TextStyle(color: AppColors.textMuted)),
                      Pill(
                        text: severityLabel(preview),
                        color: severityColor(preview),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: appInputDecoration(
                    label: 'จำนวนระบบที่ได้รับผลกระทบ',
                    hint: 'เช่น 12',
                    icon: Icons.computer,
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
              ],
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}