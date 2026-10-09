// lib/screens/edit_incident_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:exam_5_128/models/incident.dart';
import 'package:exam_5_128/theme/app_theme.dart';

// เข้าถึงได้เฉพาะ Admin (ปุ่มแก้ไขถูกซ่อนสำหรับ Operator)
class EditIncidentScreen extends StatefulWidget {
  final Incident incident;
  const EditIncidentScreen({super.key, required this.incident});

  @override
  State<EditIncidentScreen> createState() => _EditIncidentScreenState();
}

class _EditIncidentScreenState extends State<EditIncidentScreen> {
  late TextEditingController _cvssController;
  late TextEditingController _endpointsController;
  late String _containmentStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cvssController =
        TextEditingController(text: widget.incident.cvssScore.toString());
    _endpointsController = TextEditingController(
        text: widget.incident.affectedEndpoints.toString());
    _containmentStatus = kStatusOptions.contains(widget.incident.containmentStatus)
        ? widget.incident.containmentStatus
        : kStatusOptions.first;
  }

  @override
  void dispose() {
    _cvssController.dispose();
    _endpointsController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
    );
  }

  Future<void> _update() async {
    final cvss = double.tryParse(_cvssController.text.trim());
    final endpoints = int.tryParse(_endpointsController.text.trim());

    if (cvss == null || cvss < 0 || cvss > 10) {
      _showMessage('คะแนน CVSS ต้องอยู่ระหว่าง 0.0 - 10.0');
      return;
    }
    if (endpoints == null) {
      _showMessage('จำนวนระบบที่ได้รับผลกระทบต้องเป็นตัวเลข');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.incident.id)
          .update({
        'cvssScore': cvss,
        'affectedEndpoints': endpoints,
        'containmentStatus': _containmentStatus,
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('บันทึกไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final color = severityColor(incident.cvssScore);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('แก้ไขเคส'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // สรุปเคส (อ่านอย่างเดียว)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: color,
                    child: Text(
                      incident.cvssScore.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.ticketNo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          incident.attackVector,
                          style:
                              const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'อัปเดตหลังผล Audit',
              icon: Icons.fact_check_outlined,
              children: [
                TextField(
                  controller: _cvssController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: appInputDecoration(
                    label: 'คะแนน CVSS (0.0 - 10.0)',
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _endpointsController,
                  keyboardType: TextInputType.number,
                  decoration: appInputDecoration(
                    label: 'จำนวนระบบที่ได้รับผลกระทบ',
                    icon: Icons.computer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'สถานะการกักกัน',
              icon: Icons.shield_outlined,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: kStatusOptions
                      .map(
                        (s) => ChoiceChip(
                          label: Text(statusLabelThai(s)),
                          selected: _containmentStatus == s,
                          showCheckmark: false,
                          selectedColor: statusColor(s),
                          labelStyle: TextStyle(
                            color: _containmentStatus == s
                                ? Colors.white
                                : Colors.black87,
                          ),
                          onSelected: (_) =>
                              setState(() => _containmentStatus = s),
                        ),
                      )
                      .toList(),
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
              onPressed: _isSaving ? null : _update,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check),
              label: const Text('บันทึกการแก้ไข',
                  style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}