// lib/models/incident.dart
class Incident {
  final String? id;
  final String ticketNo;
  final String attackVector;
  final String investigatorEmail;
  final double cvssScore;
  final int affectedEndpoints;
  final String containmentStatus;

  Incident({
    this.id,
    required this.ticketNo,
    required this.attackVector,
    required this.investigatorEmail,
    required this.cvssScore,
    required this.affectedEndpoints,
    this.containmentStatus = 'Monitoring',
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketNo': ticketNo,
      'attackVector': attackVector,
      'investigatorEmail': investigatorEmail,
      'cvssScore': cvssScore,
      'affectedEndpoints': affectedEndpoints,
      'containmentStatus': containmentStatus,
    };
  }

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    return Incident(
      id: id,
      ticketNo: map['ticketNo'] ?? '',
      attackVector: map['attackVector'] ?? '',
      investigatorEmail: map['investigatorEmail'] ?? '',
      cvssScore: (map['cvssScore'] ?? 0).toDouble(),
      affectedEndpoints: (map['affectedEndpoints'] ?? 0).toInt(),
      containmentStatus: map['containmentStatus'] ?? 'Monitoring',
    );
  }
}