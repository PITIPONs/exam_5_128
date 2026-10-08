// lib/screens/display_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ============================================================
// ตั้งค่าชื่อ collection และชื่อฟิลด์ใน Firestore ที่ตรงนี้ที่เดียว
// ถ้าของคุณใช้ชื่ออื่น ให้แก้ค่าด้านล่างให้ตรงกับที่เห็นใน Firebase Console
// ============================================================
class _Cfg {
  static const collection = 'incidents';
  static const ticket = 'ticketNo';
  static const vector = 'attackVector';
  static const cvss = 'cvssScore';
  static const endpoints = 'affectedEndpoints';
  static const status = 'status';
  // อีเมลของเจ้าของเคส ใช้แยกข้อมูลของแต่ละบัญชี
  static const owner = 'ownerEmail';
}

// สถานะการกักกัน (Containment)
const List<String> _statusOptions = [
  'Monitoring',
  'Containing',
  'Contained',
  'Eradicated',
];

// สีตามระดับ CVSS มาตรฐาน
Color _severityColor(double score) {
  if (score >= 9.0) return const Color(0xFFB71C1C); // Critical
  if (score >= 7.0) return const Color(0xFFE65100); // High
  if (score >= 4.0) return const Color(0xFFF9A825); // Medium
  return const Color(0xFF2E7D32); // Low
}

String _severityLabel(double score) {
  if (score >= 9.0) return 'Critical';
  if (score >= 7.0) return 'High';
  if (score >= 4.0) return 'Medium';
  return 'Low';
}

Color _statusColor(String status) {
  switch (status) {
    case 'Monitoring':
      return const Color(0xFF1565C0);
    case 'Containing':
      return const Color(0xFFEF6C00);
    case 'Contained':
      return const Color(0xFF00897B);
    case 'Eradicated':
      return const Color(0xFF2E7D32);
    default:
      return Colors.grey;
  }
}

class DisplayScreen extends StatelessWidget {
  // รับ currentUser ได้ (ถ้า home_screen ส่งมา) แต่ไม่บังคับ
  final dynamic currentUser;

  const DisplayScreen({super.key, this.currentUser});

  double _toDouble(dynamic v) =>
      double.tryParse(v?.toString() ?? '') ?? 0.0;

  Future<void> _confirmDelete(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ticket = (doc.data()[_Cfg.ticket] ?? '-').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFB71C1C), size: 40),
        title: const Text('ยืนยันการปิดเคส'),
        content: Text(
          'ต้องการลบและปิดเคส "$ticket" ใช่หรือไม่?\n'
          'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบเคส'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await doc.reference.delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          content: Text('ปิดเคส $ticket เรียบร้อยแล้ว'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          content: Text('ลบไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  Future<void> _openEdit(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditDialog(
        ticket: (data[_Cfg.ticket] ?? '-').toString(),
        score: _toDouble(data[_Cfg.cvss]),
        status: (data[_Cfg.status] ?? _statusOptions.first).toString(),
      ),
    );

    if (result == null) return;

    try {
      await doc.reference.update(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          content: const Text('บันทึกการแก้ไขเรียบร้อยแล้ว'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          content: Text('แก้ไขไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ดึงอีเมลของบัญชีที่ล็อกอินอยู่ (AppUser ต้องมีฟิลด์ email)
    final String ownerEmail = (currentUser?.email ?? '').toString();

    if (ownerEmail.isEmpty) {
      return const Center(
        child: Text('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // key ผูกกับบัญชี เพื่อให้สร้าง stream ใหม่ทุกครั้งที่เปลี่ยนบัญชี
      key: ValueKey(ownerEmail),
      // แสดงเฉพาะเคสที่เป็นของบัญชีนี้เท่านั้น
      stream: FirebaseFirestore.instance
          .collection(_Cfg.collection)
          .where(_Cfg.owner, isEqualTo: ownerEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'โหลดข้อมูลไม่สำเร็จ\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.redAccent),
          );
        }

        final docs = [...?snapshot.data?.docs];

        // เรียงตามความรุนแรง (CVSS สูงสุดก่อน)
        docs.sort((a, b) => _toDouble(b.data()[_Cfg.cvss])
            .compareTo(_toDouble(a.data()[_Cfg.cvss])));

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'ยังไม่มีเหตุการณ์คุกคาม',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'เพิ่มเหตุการณ์ได้ที่แท็บ "บันทึกเหตุการณ์"',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final criticalCount = docs
            .where((d) => _toDouble(d.data()[_Cfg.cvss]) >= 9.0)
            .length;
        final activeCount = docs
            .where((d) => d.data()[_Cfg.status] != 'Eradicated')
            .length;

        return Column(
          children: [
            _SummaryBar(
              total: docs.length,
              critical: criticalCount,
              active: activeCount,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final d = doc.data();
                  return _IncidentCard(
                    ticket: (d[_Cfg.ticket] ?? '-').toString(),
                    vector: (d[_Cfg.vector] ?? '-').toString(),
                    endpoints: (d[_Cfg.endpoints] ?? 0).toString(),
                    status: (d[_Cfg.status] ?? '-').toString(),
                    score: _toDouble(d[_Cfg.cvss]),
                    onEdit: () => _openEdit(context, doc),
                    onDelete: () => _confirmDelete(context, doc),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------- แถบสรุปด้านบน ----------------
class _SummaryBar extends StatelessWidget {
  final int total;
  final int critical;
  final int active;

  const _SummaryBar({
    required this.total,
    required this.critical,
    required this.active,
  });

  Widget _item(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          _item(Icons.folder_open, 'ทั้งหมด', '$total',
              const Color(0xFF455A64)),
          const SizedBox(width: 8),
          _item(Icons.crisis_alert, 'Critical', '$critical',
              const Color(0xFFB71C1C)),
          const SizedBox(width: 8),
          _item(Icons.shield_moon_outlined, 'กำลังดำเนินการ', '$active',
              const Color(0xFF1565C0)),
        ],
      ),
    );
  }
}

// ---------------- การ์ดแต่ละเหตุการณ์ ----------------
class _IncidentCard extends StatelessWidget {
  final String ticket;
  final String vector;
  final String endpoints;
  final String status;
  final double score;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IncidentCard({
    required this.ticket,
    required this.vector,
    required this.endpoints,
    required this.status,
    required this.score,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sevColor = _severityColor(score);
    final stColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // แถบสีตามระดับความรุนแรง
              Container(width: 6, color: sevColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: sevColor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  score.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    height: 1.1,
                                  ),
                                ),
                                const Text(
                                  'CVSS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.bug_report_outlined,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        vector,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.computer,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$endpoints เครื่องติดมัลแวร์',
                                      style: TextStyle(
                                          color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Chip(
                            label: _severityLabel(score),
                            color: sevColor,
                          ),
                          const SizedBox(width: 8),
                          _Chip(label: status, color: stColor, dot: true),
                          const Spacer(),
                          IconButton(
                            tooltip: 'แก้ไข',
                            visualDensity: VisualDensity.compact,
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined),
                            color: const Color(0xFF1565C0),
                          ),
                          IconButton(
                            tooltip: 'ลบ / ปิดเคส',
                            visualDensity: VisualDensity.compact,
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                            color: const Color(0xFFB71C1C),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;

  const _Chip({required this.label, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- หน้าต่างแก้ไข ----------------
// แก้ได้: คะแนน CVSS (ระดับผลกระทบ) และสถานะการกักกัน
class _EditDialog extends StatefulWidget {
  final String ticket;
  final double score;
  final String status;

  const _EditDialog({
    required this.ticket,
    required this.score,
    required this.status,
  });

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scoreController;
  late String _status;
  late final List<String> _options;

  @override
  void initState() {
    super.initState();
    _scoreController =
        TextEditingController(text: widget.score.toStringAsFixed(1));
    _options = [..._statusOptions];
    if (!_options.contains(widget.status)) _options.add(widget.status);
    _status = widget.status;
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      _Cfg.cvss: double.parse(_scoreController.text.trim()),
      _Cfg.status: _status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('แก้ไขเหตุการณ์'),
          const SizedBox(height: 2),
          Text(
            widget.ticket,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _scoreController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'คะแนน CVSS (0.0 - 10.0)',
                prefixIcon: Icon(Icons.speed),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final v = double.tryParse((value ?? '').trim());
                if (v == null) return 'กรุณากรอกเป็นตัวเลข';
                if (v < 0 || v > 10) return 'ต้องอยู่ระหว่าง 0.0 - 10.0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'สถานะการกักกัน (Containment)',
                prefixIcon: Icon(Icons.shield_outlined),
                border: OutlineInputBorder(),
              ),
              items: _options
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: _save,
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}