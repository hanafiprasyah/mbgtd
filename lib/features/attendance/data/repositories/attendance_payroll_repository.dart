import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/core/helper/salary_calculator.dart';

class AttendancePayrollRepository {
  final firestore = FirebaseFirestore.instance;

  // This method combines volunteer and attendance data to calculate payroll information in real-time.
  Stream<Map<String, dynamic>> getPayrollStream() {
    final volunteersStream = firestore.collection('volunteers').snapshots();
    final attendanceStream = firestore.collection('attendances').snapshots();

    // The combineLatest2 operator listens to both streams and processes the data whenever either stream emits a new value.
    return Rx.combineLatest2(volunteersStream, attendanceStream, (
      QuerySnapshot volunteersSnap,
      QuerySnapshot attendanceSnap,
    ) {
      // Maps to track attendance counts, last scanned by email, effective scan counts, and half-day attendance dates for each volunteer.
      final Map<String, int> attendanceCount = {};
      final Map<String, String> lastScannedBy = {};
      final Map<String, double> effectiveScanMap = {};
      final Map<String, List<String>> halfDayDatesMap = {};
      final Map<String, List<String>> absentDatesMap = {};

      // Process attendance records to calculate total scans, effective scans, and track half-day attendances.
      for (var doc in attendanceSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final volunteerId = data['volunteerId'];

        // Increment the attendance count for the volunteer. This counts every scan, regardless of multiplier.
        attendanceCount[volunteerId] = (attendanceCount[volunteerId] ?? 0) + 1;

        // The multiplier allows for partial attendance (e.g., half-day) to be accounted for in the effective scan count.
        final multiplier = (data['multiplier'] ?? 1.0).toDouble();
        effectiveScanMap[volunteerId] =
            (effectiveScanMap[volunteerId] ?? 0) + multiplier;

        // Store partial and absent dates separately for payroll details.
        final date = (data['date'] ?? '').toString();
        final attendanceType = data['attendanceType'];
        final isAbsent = attendanceType == 'absent' || multiplier == 0;
        if (isAbsent) {
          absentDatesMap[volunteerId] = [
            ...(absentDatesMap[volunteerId] ?? []),
            date,
          ];
        } else if (multiplier < 1) {
          halfDayDatesMap[volunteerId] = [
            ...(halfDayDatesMap[volunteerId] ?? []),
            date,
          ];
        }

        // Track the last scanned by email for each volunteer. This is useful for auditing and verification purposes.
        if (data['scannedByEmail'] != null) {
          lastScannedBy[volunteerId] = data['scannedByEmail'];
        }
      }

      final Map<String, dynamic> result = {};

      // Iterate through each volunteer document to calculate their payroll information based on attendance data and whether they are a PIC (Person in Charge).
      for (var doc in volunteersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;
        final isPIC = (data['isPIC'] ?? false) == true;

        final totalScan = attendanceCount[id] ?? 0;
        final totalEffectiveScan = effectiveScanMap[id] ?? 0;
        final tim = (data['tim'] ?? '').toString().trim();

        const picBonusPerScan = 10000;

        // Base salary should ONLY depend on attendance logic
        final baseSalary = getBaseSalary(tim);
        final attendancePay = (baseSalary * totalEffectiveScan).toInt();

        // Scan bonus separated clearly
        final scanBonus = (totalEffectiveScan * picBonusPerScan).toInt();

        // Final salary
        final totalGaji = isPIC ? attendancePay + scanBonus : attendancePay;

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
          'absentDates': absentDatesMap[id] ?? [],
        };
      }

      return result;
    });
  }
}
