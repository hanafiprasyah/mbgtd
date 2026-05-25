import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    // Use composite doc ID: volunteerId + date (one scan per day per volunteer)
    final docId = '${volunteerId}_$today';
    final docRef = firestore.collection('attendances').doc(docId);

    // Prevent duplicate scan on the same day
    final doc = await docRef.get();

    if (doc.exists) {
      throw Exception('already-scanned');
    }

    // Tracker
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('user-not-logged-in');
    }

    final scannedByUid = user.uid;
    final scannedByEmail = user.email ?? 'unknown';

    // attendance object
    final attendance = Attendance(
      id: docId,
      volunteerId: volunteerId,
      nama: nama,
      tim: tim,
      timestamp: now,
      date: today,
      scannedByUid: scannedByUid,
      scannedByEmail: scannedByEmail,
    );

    final volunteerDoc = await firestore
        .collection('volunteers')
        .doc(volunteerId)
        .get();
    final isPIC = (volunteerDoc.data()?['isPIC'] ?? false) == true;

    await docRef.set({
      ...attendance.toMap(),
      'isPIC': isPIC,
      'bonus': isPIC ? 10000 : 0,
    });
  }

  Stream<int> getTotalAttendance(String volunteerId) {
    return firestore
        .collection('attendances')
        .where('volunteerId', isEqualTo: volunteerId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
