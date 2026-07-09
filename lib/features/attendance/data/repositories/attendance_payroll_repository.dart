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
          memberPayrolls['halfDayDatesMap']
              as Map<String, List<Map<String, dynamic>>>;
      final absentDatesMap =
          memberPayrolls['absentDatesMap']
              as Map<String, List<Map<String, dynamic>>>;
      final presentButReplacedDatesMap =
          memberPayrolls['presentButReplacedDatesMap']
              as Map<String, List<Map<String, dynamic>>>;
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
          'presentButReplacedDates': presentButReplacedDatesMap[id] ?? [],
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

  // ── NEW: per-volunteer attendance stream ───────────────────────────────────

  /// Streams all attendance records for [volunteerId], sorted newest-first.
  /// Each record map contains:
  ///   'id', 'date' (String YYYY-MM-DD), 'timestampMs' (int?, scan epoch ms),
  ///   'attendanceType', 'multiplier', 'note', 'scannedByEmail', 'tim'
  Stream<List<Map<String, dynamic>>> getVolunteerAttendanceStream(
    String volunteerId,
  ) {
    return firestore
        .collection('attendances')
        .where('volunteerId', isEqualTo: volunteerId)
        .snapshots()
        .map((snap) {
          final list =
              snap.docs.map((doc) {
                final data = doc.data();
                final multiplier = (data['multiplier'] ?? 1.0).toDouble();
                final attendanceType = (data['attendanceType'] ?? 'full')
                    .toString();
                final note = _getAttendanceNote(data);

                // Extract scan time from any Timestamp field present
                final ts =
                    data['createdAt'] ?? data['timestamp'] ?? data['scannedAt'];
                final int? timestampMs = ts is Timestamp
                    ? ts.toDate().millisecondsSinceEpoch
                    : null;

                return <String, dynamic>{
                  'id': doc.id,
                  'date': (data['date'] ?? '').toString(),
                  'timestampMs': timestampMs,
                  'attendanceType': attendanceType,
                  'multiplier': multiplier,
                  'note': note,
                  'scannedByEmail': (data['scannedByEmail'] ?? '').toString(),
                  'tim': (data['tim'] ?? '').toString().trim(),
                };
              }).toList()..sort(
                (a, b) => (b['date'] as String).compareTo(a['date'] as String),
              );
          return list;
        });
  }

  // ── Private helpers (unchanged) ────────────────────────────────────────────

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
    final Map<String, double> poolByProviderByDate = {};

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

        final rule = payrollRules[tim];
        final isProvider = rule?.isChefOrAslap ?? false;

        if (isProvider && multiplier > 0.0 && multiplier < 1.0) {
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
        'poolExtra': 0.0,
      };
    });

    teamDaySummary.forEach((key, summary) {
      final tim = summary['tim'] as String;
      final date = summary['date'] as String;
      final full = summary['fullCount'] as int;
      final timRule = payrollRules[tim];
      final timIsShared = timRule?.sharedPayroll ?? true;

      if (tim.toLowerCase() == 'masak') {
        final chefSummaryKey = '${date}_Chef';
        final chefSummary = teamDaySummary[chefSummaryKey];
        final chefFull = (chefSummary?['fullCount'] as int?) ?? 0;

        final masakFull = full;
        final combinedFull = masakFull + chefFull;
        final masakTotalBurden = summary['totalBurden'] as double;

        double masakBurdenPerCombinedFull = 0.0;
        if (combinedFull > 0 && masakTotalBurden > 0) {
          masakBurdenPerCombinedFull = masakTotalBurden / combinedFull;
        }

        final chefPoolKey = 'Chef_$date';
        final chefPool = poolByProviderByDate[chefPoolKey] ?? 0.0;
        double chefPoolPerMasakFull = 0.0;
        if (masakFull > 0 && chefPool > 0) {
          chefPoolPerMasakFull = chefPool / masakFull;
        }

        final masakSharePerFull =
            masakBurdenPerCombinedFull + chefPoolPerMasakFull;
        summary['sharePerFull'] = masakSharePerFull;
        summary['poolExtra'] = masakSharePerFull;
        summary['chefExtraPerMasakFull'] = chefPoolPerMasakFull;

        if (chefSummary != null && masakBurdenPerCombinedFull > 0) {
          chefSummary['extraFromMasakBurden'] = masakBurdenPerCombinedFull;
          chefSummary['poolExtra'] = masakBurdenPerCombinedFull;
        }
      } else if (tim.toLowerCase() == 'aslap') {
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
      } else if (timIsShared) {
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
    final Map<String, List<Map<String, dynamic>>> halfDayDatesMap = {};
    final Map<String, List<Map<String, dynamic>>> absentDatesMap = {};
    final Map<String, List<Map<String, dynamic>>> presentButReplacedDatesMap =
        {};
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
      final note = _getAttendanceNote(data);
      final tim = (data['tim'] ?? '').toString().trim();
      final key = '${date}_$tim';
      final attendanceType = (data['attendanceType'] ?? 'full') as String;
      final attendanceItem = {
        'date': date,
        'note': note,
        'attendanceType': attendanceType,
        'multiplier': multiplier,
      };

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

      final isFullDay = multiplier >= 1.0 && attendanceType != 'absent';
      final extraFromMasakBurden = (isFullDay && teamSummary != null)
          ? ((teamSummary['extraFromMasakBurden'] as double?) ?? 0.0)
          : 0.0;
      if (extraFromMasakBurden > 0) {
        memberTotalPay[volunteerId] =
            (memberTotalPay[volunteerId] ?? 0.0) + extraFromMasakBurden;
      }

      if (attendanceType == 'absent' || multiplier == 0.0) {
        absentDatesMap[volunteerId] = [
          ...(absentDatesMap[volunteerId] ?? []),
          attendanceItem,
        ];
      } else if (multiplier < 1.0) {
        halfDayDatesMap[volunteerId] = [
          ...(halfDayDatesMap[volunteerId] ?? []),
          attendanceItem,
        ];
      } else if (multiplier == 1.0 && note.trim() != 'Full attendance') {
        presentButReplacedDatesMap[volunteerId] = [
          ...(presentButReplacedDatesMap[volunteerId] ?? []),
          attendanceItem,
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
      'presentButReplacedDatesMap': presentButReplacedDatesMap,
      'lastScannedBy': lastScannedBy,
    };
  }

  String _getAttendanceNote(Map<String, dynamic> data) {
    return (data['note'] ??
            data['notes'] ??
            data['reason'] ??
            data['keterangan'] ??
            '')
        .toString()
        .trim();
  }

  Future<Map<String, dynamic>> getPayrollSnapshot() async {
    final volunteersSnap = await firestore.collection('volunteers').get();
    final attendanceSnap = await firestore.collection('attendances').get();

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

    final Map<String, Map<String, dynamic>> volunteersMap = {};

    for (var doc in volunteersSnap.docs) {
      final data = doc.data();
      final id = doc.id;
      final isPIC = (data['isPIC'] ?? false) == true;
      final tim = (data['tim'] ?? '').toString().trim();
      final nama = data['namaLengkap'] ?? '-';

      final totalScan = memberTotalScan[id] ?? 0;
      final totalEffectiveScan = memberEffectiveScan[id] ?? 0.0;
      final totalGajiDouble = memberTotalPay[id] ?? 0.0;

      const picBonusPerScan = 10000;
      final scanBonus = (totalEffectiveScan * picBonusPerScan).toInt();
      final totalGaji = isPIC
          ? (totalGajiDouble.toInt() + scanBonus)
          : totalGajiDouble.toInt();

      final dailyList = <Map<String, dynamic>>[];
      final attendanceDocs = attendanceSnap.docs.where((d) {
        final dData = d.data();
        return dData['volunteerId'] == id;
      });

      for (var attDoc in attendanceDocs) {
        final attData = attDoc.data();
        final multiplier = (attData['multiplier'] ?? 1.0).toDouble();
        final attendanceType = attData['attendanceType'] ?? 'full';
        final date = attData['date'] ?? '';
        dailyList.add({
          'date': date,
          'multiplier': multiplier,
          'attendanceType': attendanceType,
        });
      }

      volunteersMap[id] = {
        'id': id,
        'nama': nama,
        'tim': tim,
        'totalGaji': totalGaji,
        'isPIC': isPIC,
        'totalScan': totalScan,
        'effectiveScan': totalEffectiveScan,
        'dailyDetails': dailyList,
      };
    }

    final Map<String, int> teamTotal = {};
    int grandTotal = 0;

    for (final volunteer in volunteersMap.values) {
      final tim = volunteer['tim'] as String;
      final gaji = volunteer['totalGaji'] as int;
      teamTotal[tim] = (teamTotal[tim] ?? 0) + gaji;
      grandTotal += gaji;
    }

    return {
      'resetAt': DateTime.now(),
      'volunteers': volunteersMap,
      'teamTotal': teamTotal,
      'grandTotal': grandTotal,
    };
  }
}
