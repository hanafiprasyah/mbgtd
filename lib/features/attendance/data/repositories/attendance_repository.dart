import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  final firestore = FirebaseFirestore.instance;

  Future<void> scanAttendance({
    required String volunteerId,
    required String nama,
    required String tim,
  }) async {
    final now = DateTime.now();
    final yyyy = now.year.toString().padLeft(4, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final today = '$yyyy-$mm-$dd';

    // Deterministic doc ID: one doc per volunteer per day
    final docId = volunteerId;
    final docRef = firestore.collection('attendances').doc(docId);

    final doc = await docRef.get();

    if (doc.exists) {
      throw Exception('already-scanned');
    }

    final attendance = Attendance(
      id: docId,
      volunteerId: volunteerId,
      nama: nama,
      tim: tim,
      timestamp: now,
      date: today,
    );

    await docRef.set(attendance.toMap());
  }

  Stream<int> getTotalAttendance(String volunteerId) {
    return firestore
        .collection('attendances')
        .where('volunteerId', isEqualTo: volunteerId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
