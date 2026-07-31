import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/features/attendance/data/models/payroll_period_model.dart';
import 'package:rxdart/rxdart.dart';

/// Read-only reporting gateway for archived payroll snapshots.
///
/// Attendance documents are removed at the end of a cycle, therefore reports
/// deliberately use `payroll_periods` as their source of truth.  The nested
/// `volunteers` map is keyed by the volunteer document id, not Firebase Auth
/// UID; callers that need a personal slip must resolve `volunteers.userId`
/// first (see [getMyPayrollHistory]).
class PayrollReportRepository {
  PayrollReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<PayrollPeriod>> watchPayrollPeriods() {
    return _firestore
        .collection('payroll_periods')
        .orderBy('resetAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PayrollPeriod.fromFirestore).toList());
  }

  /// Loads payroll snapshots that contain the volunteer linked to [authUid].
  /// The auth UID is never used as a payroll-map key because those keys are
  /// Firestore volunteer document IDs.
  Stream<List<PayrollPeriod>> getMyPayrollHistory(String authUid) {
    return _firestore
        .collection('volunteers')
        .where('userId', isEqualTo: authUid)
        .limit(1)
        .snapshots()
        .switchMap((volunteerSnap) {
          if (volunteerSnap.docs.isEmpty) {
            return Stream.value(<PayrollPeriod>[]);
          }
          final volunteerId = volunteerSnap.docs.first.id;
          return _firestore
              .collection('payroll_periods')
              .orderBy('resetAt', descending: true)
              .snapshots()
              .map(
                (periods) => periods.docs
                    .map(PayrollPeriod.fromFirestore)
                    .where(
                      (period) => period.volunteers.containsKey(volunteerId),
                    )
                    .map(
                      (period) => PayrollPeriod(
                        id: period.id,
                        resetAt: period.resetAt,
                        grandTotal: period.grandTotal,
                        teamTotal: period.teamTotal,
                        volunteers: {
                          volunteerId: period.volunteers[volunteerId]!,
                        },
                      ),
                    )
                    .toList(),
              );
        });
  }
}
