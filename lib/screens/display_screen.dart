// lib/screens/display_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:exam_5_128/models/app_user.dart';
import 'package:exam_5_128/models/incident.dart';
import 'package:exam_5_128/screens/edit_incident_screen.dart';
import 'package:exam_5_128/theme/app_theme.dart';

class DisplayScreen extends StatefulWidget {
  final AppUser currentUser;
  const DisplayScreen({super.key, required this.currentUser});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  String _filter = 'All';
  final _filters = const ['All', 'Critical', 'High', 'Medium', 'Low'];

  String _filterLabel(String f) => f == 'All' ? 'ทั้งหมด' : f;

  bool _match(Incident i) {
    if (_filter == 'All') return true;
    return severityLabel(i.cvssScore) == _filter;
  }

  Future<void> _confirmDelete(Incident incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.accent, size: 36),
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'ต้องการลบเคส "${incident.ticketNo}" ใช่หรือไม่?\nการลบไม่สามารถกู้คืนได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(incident.id)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('ลบเคสเรียบร้อย'),
        ),
      );
    }
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Incident incident) {
    final color = severityColor(incident.cvssScore);
    final isAdmin = widget.currentUser.isAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(),
      child: Column(
        children: [
          ListTile(
            isThreeLine: true,
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Text(
                incident.cvssScore.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              incident.ticketNo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report_outlined,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          incident.attackVector,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.computer,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${incident.affectedEndpoints} เครื่องได้รับผลกระทบ'),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Pill(
              text: severityLabel(incident.cvssScore),
              color: color,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Pill(
                  text: statusLabelThai(incident.containmentStatus),
                  color: statusColor(incident.containmentStatus),
                  icon: Icons.shield_outlined,
                ),
                const Spacer(),
                // เฉพาะ Admin เท่านั้นที่เห็นปุ่มแก้ไข/ลบ
                if (isAdmin) ...[
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditIncidentScreen(incident: incident),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('แก้ไข'),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.critical),
                    onPressed: () => _confirmDelete(incident),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('ลบ'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('incidents')
          .orderBy('cvssScore', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                  textAlign: TextAlign.center),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final incidents = snapshot.data!.docs
            .map((d) =>
                Incident.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList();
        final shown = incidents.where(_match).toList();

        final total = incidents.length;
        final critical =
            incidents.where((i) => i.cvssScore >= 9).length;
        final endpoints =
            incidents.fold<int>(0, (sum, i) => sum + i.affectedEndpoints);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _statCard('เคสทั้งหมด', '$total', Icons.folder_open,
                          AppColors.navy),
                      const SizedBox(width: 10),
                      _statCard('วิกฤต', '$critical',
                          Icons.local_fire_department, AppColors.critical),
                      const SizedBox(width: 10),
                      _statCard('เครื่องที่โดน', '$endpoints',
                          Icons.computer, AppColors.medium),
                    ],
                  ),
                  if (!widget.currentUser.isAdmin) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Color(0xFF1D4ED8), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'บัญชี Operator: ดูรายการและแจ้งเหตุใหม่ได้ แต่แก้ไข/ลบไม่ได้',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters
                          .map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(_filterLabel(f)),
                                selected: _filter == f,
                                showCheckmark: false,
                                selectedColor: AppColors.navy,
                                labelStyle: TextStyle(
                                  color: _filter == f
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                onSelected: (_) =>
                                    setState(() => _filter = f),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text('ยังไม่มีรายการเหตุการณ์',
                              style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: shown.length,
                      itemBuilder: (context, index) =>
                          _buildItem(shown[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}