import '../models/attendance_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/features/attendance/data/models/attendance_period.dart';
import 'package:rxdart/rxdart.dart';

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

    // Ensure the volunteer exists and is still active (not resigned)
    final volunteerDoc = await firestore
        .collection('volunteers')
        .doc(volunteerId)
        .get();

    if (!volunteerDoc.exists) {
      throw Exception('volunteer-not-found');
    }

    final isActive = (volunteerDoc.data()?['isActive'] ?? true) == true;
    if (!isActive) {
      throw Exception('volunteer-inactive');
    }

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

  // This method retrieves the attendance periods from the Firestore database. It fetches the documents from the 'attendance_periods' collection, orders them by the 'resetAt' field in descending order, and maps each document to an AttendancePeriod object. The result is a list of attendance periods that can be used to determine the current active period for attendance tracking.
  Future<List<AttendancePeriod>> getAttendancePeriods() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance_periods')
          .orderBy('resetAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => AttendancePeriod.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load periods: $e');
    }
  }

  // Reminder: active volunteer who has not scanned attendance today or for the last 2 days
  Stream<Map<String, List<Map<String, dynamic>>>> getAbsenceReminders() {
    final volunteersStream = firestore
        .collection('volunteers')
        .where('isActive', isEqualTo: true)
        .snapshots();
    final attendanceStream = firestore.collection('attendances').snapshots();

    return Rx.combineLatest2<
          QuerySnapshot,
          QuerySnapshot,
          Map<String, List<Map<String, dynamic>>>
        >(volunteersStream, attendanceStream, (volunteersSnap, attendanceSnap) {
          final now = DateTime.now();
          final todayStr = _dateKey(now);

          // Last scan date per volunteer
          final Map<String, String> lastScanDate = {};
          for (var doc in attendanceSnap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final volunteerId = data['volunteerId']?.toString();
            final date = (data['date'] ?? '').toString();
            if (volunteerId == null || date.isEmpty) continue;
            final current = lastScanDate[volunteerId];
            if (current == null || date.compareTo(current) > 0) {
              lastScanDate[volunteerId] = date;
            }
          }

          final notScannedToday = <Map<String, dynamic>>[];
          final notScanned2Days = <Map<String, dynamic>>[];

          for (var doc in volunteersSnap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            final last = lastScanDate[id];
            final scannedToday = last == todayStr;
            if (scannedToday) continue;

            final daysSince = last == null
                ? null
                : now.difference(DateTime.parse(last)).inDays;

            final item = {
              'id': id,
              'nama': (data['namaLengkap'] ?? '-').toString(),
              'tim': (data['tim'] ?? '').toString().trim(),
              'lastScanDate': last,
              'daysSince': daysSince,
            };

            notScannedToday.add(item);
            if (last == null || daysSince! >= 2) {
              notScanned2Days.add(item);
            }
          }

          notScannedToday.sort(
            (a, b) => (a['nama'] as String).compareTo(b['nama'] as String),
          );
          notScanned2Days.sort(
            (a, b) =>
                (b['daysSince'] ?? 9999).compareTo(a['daysSince'] ?? 9999)
                    as int,
          );

          return {
            'notScannedToday': notScannedToday,
            'notScanned2Days': notScanned2Days,
          };
        })
        .handleError((error, stack) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            return;
          }
          throw error;
        });
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
