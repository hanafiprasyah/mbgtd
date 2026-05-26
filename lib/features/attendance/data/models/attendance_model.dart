import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String volunteerId;
  final String nama;
  final String tim;
  final DateTime timestamp;
  final String date;
  final String scannedByUid;
  final String scannedByEmail;
  final String attendanceType;
  final double multiplier;
  final String note;

  Attendance({
    required this.id,
    required this.volunteerId,
    required this.nama,
    required this.tim,
    required this.timestamp,
    required this.date,
    required this.scannedByUid,
    required this.scannedByEmail,
    this.attendanceType = "full",
    this.multiplier = 1.0,
    this.note = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'nama': nama,
      'tim': tim,
      'timestamp': Timestamp.fromDate(timestamp),
      'date': date,
      'scannedByUid': scannedByUid,
      'scannedByEmail': scannedByEmail,
      'attendanceType': attendanceType,
      'multiplier': multiplier,
      'note': note,
    };
  }
}
