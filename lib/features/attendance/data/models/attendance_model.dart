import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String volunteerId;
  final String nama;
  final String tim;
  final DateTime timestamp;
  final String date;

  Attendance({
    required this.id,
    required this.volunteerId,
    required this.nama,
    required this.tim,
    required this.timestamp,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'nama': nama,
      'tim': tim,
      'timestamp': Timestamp.fromDate(timestamp),
      'date': date,
    };
  }
}
