import '../models/attendance_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRepository {
  final firestore = FirebaseFirestore.instance;

  // This method handles the scanning of attendance for a volunteer. It ensures that a volunteer can only scan once per day and records the necessary information about the scan, including who scanned it and whether the volunteer is a PIC (Person in Charge).
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
      attendanceType: "full",
      multiplier: 1.0,
      note: "Full attendance",
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

  // This method retrieves the payroll information for all volunteers based on their attendance records. It calculates the total scans, effective scans (accounting for partial attendance), and any bonuses for PICs (Persons in Charge). The result is a map containing detailed payroll information for each volunteer.
  Stream<int> getTotalAttendance(String volunteerId) {
    return firestore
        .collection('attendances')
        .where('volunteerId', isEqualTo: volunteerId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
