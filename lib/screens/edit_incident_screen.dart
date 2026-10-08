// lib/screens/edit_incident_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:exam_5_128/models/incident.dart';

// เข้าถึงได้เฉพาะ Admin (ปุ่ม Edit ถูกซ่อนสำหรับ Operator ที่ DisplayScreen)
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

  final _statusOptions = const ['Monitoring', 'Contained', 'Eradicated', 'Closed'];

  @override
  void initState() {
    super.initState();
    _cvssController =
        TextEditingController(text: widget.incident.cvssScore.toString());
    _endpointsController = TextEditingController(
        text: widget.incident.affectedEndpoints.toString());
    _containmentStatus = _statusOptions.contains(widget.incident.containmentStatus)
        ? widget.incident.containmentStatus
        : _statusOptions.first;
  }

  @override
  void dispose() {
    _cvssController.dispose();
    _endpointsController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final cvss = double.tryParse(_cvssController.text);
    final endpoints = int.tryParse(_endpointsController.text);

    if (cvss == null || cvss < 0 || cvss > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คะแนน CVSS ต้องอยู่ระหว่าง 0.0 - 10.0')),
      );
      return;
    }
    if (endpoints == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('จำนวนระบบที่ได้รับผลกระทบต้องเป็นตัวเลข')),
      );
      return;
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไข ${widget.incident.ticketNo}'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ประเภทภัยคุกคาม: ${widget.incident.attackVector}'),
            const SizedBox(height: 16),
            const Text('คะแนนความเสี่ยง CVSS Score'),
            TextField(
              controller: _cvssController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            const Text('จำนวนระบบที่ได้รับผลกระทบ'),
            TextField(
              controller: _endpointsController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('สถานะการกักกัน (Containment Status)'),
            DropdownButton<String>(
              isExpanded: true,
              value: _containmentStatus,
              items: _statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _containmentStatus = value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: _update,
                child: const Text('บันทึกการแก้ไข'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}