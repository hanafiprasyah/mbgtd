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
      final Map<String, double> effectiveScanMap = {};
      final Map<String, List<String>> halfDayDatesMap = {};

      for (var doc in attendanceSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final volunteerId = data['volunteerId'];

        attendanceCount[volunteerId] = (attendanceCount[volunteerId] ?? 0) + 1;

        final multiplier = (data['multiplier'] ?? 1.0).toDouble();
        effectiveScanMap[volunteerId] =
            (effectiveScanMap[volunteerId] ?? 0) + multiplier;

        final date = (data['date'] ?? '').toString();
        if (multiplier < 1) {
          halfDayDatesMap[volunteerId] = [
            ...(halfDayDatesMap[volunteerId] ?? []),
            date,
          ];
        }

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
        final totalEffectiveScan = effectiveScanMap[id] ?? 0;
        final tim = (data['tim'] ?? '').toString().trim();

        const picBonusPerScan = 10000;

        // Salary now based on effectiveScan (converted to int for compatibility)
        final baseSalary = calculateSalary(totalEffectiveScan.toInt(), tim);

        // PIC bonus should also follow effectiveScan (not totalScan)
        final totalGaji = isPIC
            ? baseSalary + (totalEffectiveScan * picBonusPerScan).toInt()
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
          'effectiveScan': totalEffectiveScan,
          'halfDayDates': halfDayDatesMap[id] ?? [],
        };
      }

      return result;
    });
  }
}
