import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/core/helper/salary_calculator.dart';

class AttendancePayrollRepository {
  final firestore = FirebaseFirestore.instance;

  Stream<Map<String, dynamic>> getPayrollStream() {
    final volunteersStream = firestore.collection('volunteers').snapshots();
    final attendanceStream = firestore.collection('attendances').snapshots();

    return Rx.combineLatest2<
      QuerySnapshot,
      QuerySnapshot,
      Map<String, dynamic>
    >(volunteersStream, attendanceStream, (
      QuerySnapshot volunteersSnap,
      QuerySnapshot attendanceSnap,
    ) {
      final grouped = _groupAttendanceByDateTim(attendanceSnap);
      final teamDaySummaryResult = _computeTeamDaySummaryFromGroups(grouped);
      final teamDaySummary =
          teamDaySummaryResult['teamDaySummary']
              as Map<String, Map<String, dynamic>>;

      final memberPayrolls = _computeMemberPayrolls(
        attendanceSnap,
        teamDaySummary,
      );
      final memberTotalPay =
          memberPayrolls['memberTotalPay'] as Map<String, double>;
      final memberTotalScan =
          memberPayrolls['memberTotalScan'] as Map<String, int>;
      final memberEffectiveScan =
          memberPayrolls['memberEffectiveScan'] as Map<String, double>;
      final halfDayDatesMap =
          memberPayrolls['halfDayDatesMap'] as Map<String, List<String>>;
      final absentDatesMap =
          memberPayrolls['absentDatesMap'] as Map<String, List<String>>;
      final lastScannedBy =
          memberPayrolls['lastScannedBy'] as Map<String, String>;

      final Map<String, dynamic> result = {};

      for (var doc in volunteersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;
        final isPIC = (data['isPIC'] ?? false) == true;

        final totalScan = memberTotalScan[id] ?? 0;
        final totalEffectiveScan = memberEffectiveScan[id] ?? 0.0;
        final totalGajiDouble = memberTotalPay[id] ?? 0.0;

        const picBonusPerScan = 10000;
        final scanBonus = (totalEffectiveScan * picBonusPerScan).toInt();
        final totalGaji = isPIC
            ? (totalGajiDouble.toInt() + scanBonus)
            : totalGajiDouble.toInt();

        final tim = (data['tim'] ?? '').toString().trim();

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

  Stream<Map<String, Map<String, dynamic>>> getTeamDaySummaryStream() {
    return firestore.collection('attendances').snapshots().map((
      attendanceSnap,
    ) {
      final grouped = _groupAttendanceByDateTim(attendanceSnap);
      final teamDaySummaryResult = _computeTeamDaySummaryFromGroups(grouped);
      return teamDaySummaryResult['teamDaySummary']
          as Map<String, Map<String, dynamic>>;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupAttendanceByDateTim(
    QuerySnapshot attendanceSnap,
  ) {
    final Map<String, List<Map<String, dynamic>>> groupByDateTim = {};
    for (var doc in attendanceSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] ?? '').toString();
      final tim = (data['tim'] ?? '').toString().trim();
      final key = '${date}_$tim';

      groupByDateTim.putIfAbsent(key, () => []).add({
        'id': doc.id,
        'volunteerId': data['volunteerId'],
        'attendanceType': data['attendanceType'] ?? 'full',
        'multiplier': (data['multiplier'] ?? 1.0).toDouble(),
        'date': date,
        'tim': tim,
        'scannedByEmail': data['scannedByEmail'],
      });
    }

    return groupByDateTim;
  }

  Map<String, dynamic> _computeTeamDaySummaryFromGroups(
    Map<String, List<Map<String, dynamic>>> groupByDateTim,
  ) {
    final Map<String, Map<String, dynamic>> teamDaySummary = {};
    final Map<String, double> poolByProviderByDate =
        {}; // "{provider}_{date}" -> amount

    // First pass: find the most recent halfday date for each pool provider (Chef, ASLAP, etc.)
    final Map<String, String?> mostRecentHalfDayDatePerProvider = {};

    groupByDateTim.forEach((key, list) {
      final split = key.split('_');
      final date = split[0];
      final tim = split.sublist(1).join('_');

      final rule = payrollRules[tim];
      final isProvider = rule?.isChefOrAslap ?? false;

      if (isProvider) {
        for (var rec in list) {
          final multiplier = (rec['multiplier'] ?? 1.0) as double;
          // Check if provider has halfday (0 < multiplier < 1)
          if (multiplier > 0.0 && multiplier < 1.0) {
            final currentRecent = mostRecentHalfDayDatePerProvider[tim];
            if (currentRecent == null || date.compareTo(currentRecent) > 0) {
              mostRecentHalfDayDatePerProvider[tim] = date;
            }
          }
        }
      }
    });

    // Second pass: compute team day summary and calculate pool from providers
    groupByDateTim.forEach((key, list) {
      final split = key.split('_');
      final date = split[0];
      final tim = split.sublist(1).join('_');

      int fullCount = 0;
      int halfCount = 0;
      int absentCount = 0;

      for (var rec in list) {
        final multiplier = (rec['multiplier'] ?? 1.0) as double;
        final attendanceType = (rec['attendanceType'] ?? 'full') as String;

        final isAbsent = attendanceType == 'absent' || multiplier == 0.0;
        if (isAbsent) {
          absentCount += 1;
        } else if (multiplier < 1.0) {
          halfCount += 1;
        } else {
          fullCount += 1;
        }

        // Calculate pool contribution from providers
        final rule = payrollRules[tim];
        final isProvider = rule?.isChefOrAslap ?? false;

        if (isProvider &&
            multiplier > 0.0 &&
            multiplier < 1.0 &&
            date == mostRecentHalfDayDatePerProvider[tim]) {
          // Provider halfday on most recent date contributes to pool
          final providerBase = getBaseSalary(tim);
          final poolKey = '${tim}_$date';
          poolByProviderByDate[poolKey] =
              (poolByProviderByDate[poolKey] ?? 0.0) +
              multiplier * providerBase;
        }
      }

      final baseSalary = getBaseSalary(tim);
      final rule = payrollRules[tim];
      final shared = rule?.sharedPayroll ?? true;

      double missingWorkload = 0.0;
      double totalBurden = 0.0;
      double sharePerFull = 0.0;

      if (shared) {
        missingWorkload = calculateMissingWorkload(halfCount, absentCount);
        totalBurden = calculateTotalBurden(baseSalary, missingWorkload);
        sharePerFull = calculateSharePerFulltime(fullCount, totalBurden);
      }

      teamDaySummary[key] = {
        'date': date,
        'tim': tim,
        'fullCount': fullCount,
        'halfCount': halfCount,
        'absentCount': absentCount,
        'baseSalary': baseSalary,
        'shared': shared,
        'missingWorkload': missingWorkload,
        'totalBurden': totalBurden,
        'sharePerFull': sharePerFull,
        'poolExtra': 0.0, // Will be filled in third pass
      };
    });

    // Third pass: distribute pool from providers to their receivers
    // Chef provides pool to Masak
    teamDaySummary.forEach((key, summary) {
      final tim = summary['tim'] as String;
      final date = summary['date'] as String;
      final full = summary['fullCount'] as int;
      final timRule = payrollRules[tim];
      final timIsShared = timRule?.sharedPayroll ?? true;

      // Check if Chef has pool for this date
      if (tim.toLowerCase() == 'masak') {
        final chefPoolKey = 'Chef_$date';
        final chefPool = poolByProviderByDate[chefPoolKey] ?? 0.0;
        if (full > 0 && chefPool > 0) {
          final chefExtra = chefPool / full;
          summary['poolExtra'] = chefExtra;
          summary['chefExtraPerMasakFull'] =
              chefExtra; // Keep for backwards compatibility
          summary['sharePerFull'] =
              (summary['sharePerFull'] as double) + chefExtra;
        } else {
          summary['poolExtra'] = 0.0;
          summary['chefExtraPerMasakFull'] = 0.0;
        }
      }
      // ASLAP provides pool to ASLAP (self)
      else if (tim.toLowerCase() == 'aslap') {
        final aslapPoolKey = 'ASLAP_$date';
        final aslapPool = poolByProviderByDate[aslapPoolKey] ?? 0.0;
        if (full > 0 && aslapPool > 0) {
          final aslapExtra = aslapPool / full;
          summary['poolExtra'] = aslapExtra;
          summary['sharePerFull'] =
              (summary['sharePerFull'] as double) + aslapExtra;
        } else {
          summary['poolExtra'] = 0.0;
        }
      }
      // For other shared teams (Packing, Persiapan, etc): pool is from their own shared burden
      else if (timIsShared) {
        final totalBurden = summary['totalBurden'] as double;
        if (full > 0 && totalBurden > 0) {
          final poolExtra = totalBurden / full;
          summary['poolExtra'] = poolExtra;
        } else {
          summary['poolExtra'] = 0.0;
        }
      }
    });

    return {
      'teamDaySummary': teamDaySummary,
      'poolByProviderByDate': poolByProviderByDate,
    };
  }

  Map<String, dynamic> _computeMemberPayrolls(
    QuerySnapshot attendanceSnap,
    Map<String, Map<String, dynamic>> teamDaySummary,
  ) {
    final Map<String, double> memberTotalPay = {};
    final Map<String, int> memberTotalScan = {};
    final Map<String, double> memberEffectiveScan = {};
    final Map<String, List<String>> halfDayDatesMap = {};
    final Map<String, List<String>> absentDatesMap = {};
    final Map<String, String> lastScannedBy = {};

    for (var doc in attendanceSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final volunteerId = data['volunteerId'];
      if (volunteerId == null) continue;

      memberTotalScan[volunteerId] = (memberTotalScan[volunteerId] ?? 0) + 1;
      final multiplier = (data['multiplier'] ?? 1.0).toDouble();
      memberEffectiveScan[volunteerId] =
          (memberEffectiveScan[volunteerId] ?? 0) + multiplier;

      final date = (data['date'] ?? '').toString();
      final tim = (data['tim'] ?? '').toString().trim();
      final key = '${date}_$tim';
      final attendanceType = (data['attendanceType'] ?? 'full') as String;

      final teamSummary = teamDaySummary[key];
      final baseSalary = getBaseSalary(tim);
      final shared = teamSummary?['shared'] as bool? ?? true;
      final sharePerFull = teamSummary?['sharePerFull'] as double? ?? 0.0;

      final payForThisScan = calculateMemberPay(
        attendanceType: attendanceType,
        multiplier: multiplier,
        baseSalary: baseSalary,
        sharePerFulltime: sharePerFull,
        sharedPayroll: shared,
      );

      memberTotalPay[volunteerId] =
          (memberTotalPay[volunteerId] ?? 0.0) + payForThisScan;

      if (attendanceType == 'absent' || multiplier == 0.0) {
        absentDatesMap[volunteerId] = [
          ...(absentDatesMap[volunteerId] ?? []),
          date,
        ];
      } else if (multiplier < 1.0) {
        halfDayDatesMap[volunteerId] = [
          ...(halfDayDatesMap[volunteerId] ?? []),
          date,
        ];
      }

      if (data['scannedByEmail'] != null) {
        lastScannedBy[volunteerId] = data['scannedByEmail'];
      }
    }

    return {
      'memberTotalPay': memberTotalPay,
      'memberTotalScan': memberTotalScan,
      'memberEffectiveScan': memberEffectiveScan,
      'halfDayDatesMap': halfDayDatesMap,
      'absentDatesMap': absentDatesMap,
      'lastScannedBy': lastScannedBy,
    };
  }
}
