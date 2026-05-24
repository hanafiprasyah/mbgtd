import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mbg_test/core/helper/salary_calculator.dart';

class AttendancePayrollRepository {
  final firestore = FirebaseFirestore.instance;

  Stream<Map<String, dynamic>> getPayrollStream() {
    final volunteersStream = firestore.collection('volunteers').snapshots();
    final attendanceStream = firestore.collection('attendances').snapshots();

    return Rx.combineLatest2(volunteersStream, attendanceStream, (
      QuerySnapshot volunteersSnap,
      QuerySnapshot attendanceSnap,
    ) {
      final Map<String, int> attendanceCount = {};
      final Map<String, String> lastScannedBy = {};

      for (var doc in attendanceSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final volunteerId = data['volunteerId'];

        attendanceCount[volunteerId] = (attendanceCount[volunteerId] ?? 0) + 1;

        if (data['scannedByEmail'] != null) {
          lastScannedBy[volunteerId] = data['scannedByEmail'];
        }
      }

      final Map<String, dynamic> result = {};

      for (var doc in volunteersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;
        final isPIC = (data['isPIC'] ?? false) == true;

        final totalScan = attendanceCount[id] ?? 0;
        final tim = (data['tim'] ?? '').toString().trim();

        const picBonusPerScan = 10000;
        final baseSalary = calculateSalary(totalScan, tim);
        final totalGaji = isPIC
            ? baseSalary + (totalScan * picBonusPerScan)
            : baseSalary;

        result[id] = {
          'id': id,
          ...data,
          'nama': data['namaLengkap'],
          'tim': tim,
          'totalScan': totalScan,
          'totalGaji': totalGaji,
          'isPIC': isPIC,
          'scannedByEmail': lastScannedBy[id] ?? '-',
        };
      }

      return result;
    });
  }
}
