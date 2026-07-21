import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_sp_history_model.dart';

class VolunteerRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Fetch all volunteers
  Stream<List<Volunteer>> getVolunteer() {
    return firestore
        .collection('volunteers')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Volunteer.fromFirestore(doc)).toList(),
        );
  }

  // Add a new volunteer
  Future<void> addVolunteer(Volunteer volunteer) async {
    await firestore.collection('volunteers').add(volunteer.toMap());
  }

  // Update an existing volunteer
  Future<void> updateVolunteer(Volunteer volunteer) async {
    await firestore
        .collection('volunteers')
        .doc(volunteer.id)
        .update(volunteer.toMap());
  }

  // Delete a volunteer
  Future<void> deleteVolunteer(String id) async {
    await firestore.collection('volunteers').doc(id).delete();
  }

  // Toggle volunteer's active status
  Future<void> toggleVolunteerStatus(String id, bool currentStatus) async {
    await firestore.collection('volunteers').doc(id).update({
      'isActive': !currentStatus,
    });
  }

  /// Escalates a volunteer's warning level (SP 1 → SP 2 → SP 3) and logs
  /// the action, with [reason], to the `volunteer_sp_history` collection.
  /// [currentLevel] is the level the volunteer is on *before* this call
  /// (0 = none, 1 = SP 1, 2 = SP 2). Reaching SP 3 also sets isActive
  /// to false. Already at SP 3 is a no-op (SP 3 is a terminal state that
  /// only clears through an explicit undo).
  Future<void> escalateVolunteerSP(
    String id,
    int currentLevel,
    String reason, {
    String? volunteerName,
    String? performedBy,
  }) async {
    if (currentLevel >= 3) return;

    final newLevel = currentLevel + 1;
    final batch = firestore.batch();

    final volunteerRef = firestore.collection('volunteers').doc(id);
    final updateData = <String, dynamic>{'spLevel': newLevel};
    if (newLevel >= 3) {
      updateData['isActive'] = false;
    }
    batch.update(volunteerRef, updateData);

    final historyRef = firestore.collection('volunteer_sp_history').doc();
    batch.set(historyRef, {
      'volunteerId': id,
      'volunteerName': volunteerName ?? '',
      'action': 'issued',
      'previousLevel': currentLevel,
      'newLevel': newLevel,
      'reason': reason,
      'performedBy': performedBy,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Undoes a volunteer's SP record back to a clean state (spLevel: 0),
  /// logging [reason] to the history collection. If the volunteer was at
  /// SP 3 (and therefore deactivated by the earlier escalation), undoing
  /// it also reactivates them (isActive: true) — SP 3's deactivation and
  /// its undo are treated as a single reversible unit.
  Future<void> resetVolunteerSP(
    String id,
    int currentLevel,
    String reason, {
    String? volunteerName,
    String? performedBy,
  }) async {
    if (currentLevel <= 0) return;

    final batch = firestore.batch();

    final volunteerRef = firestore.collection('volunteers').doc(id);
    final updateData = <String, dynamic>{'spLevel': 0};
    if (currentLevel >= 3) {
      updateData['isActive'] = true;
    }
    batch.update(volunteerRef, updateData);

    final historyRef = firestore.collection('volunteer_sp_history').doc();
    batch.set(historyRef, {
      'volunteerId': id,
      'volunteerName': volunteerName ?? '',
      'action': 'undo',
      'previousLevel': currentLevel,
      'newLevel': 0,
      'reason': reason,
      'performedBy': performedBy,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Full SP timeline for a volunteer, newest first — every issue and
  /// undo action with its date, level change, and reason.
  Stream<List<VolunteerSpHistory>> getVolunteerSPHistory(String volunteerId) {
    return firestore
        .collection('volunteer_sp_history')
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VolunteerSpHistory.fromFirestore(doc))
              .toList(),
        );
  }

  /// Same as [getVolunteerSPHistory], but for self-service screens that
  /// only know the signed-in Firebase Auth uid, not the volunteer doc id.
  /// Resolves the linked volunteer (`volunteers.userId == userId`) first,
  /// then streams its SP history. Emits an empty list if the account
  /// isn't linked to a volunteer record.
  ///
  /// Also guards against a common sign-out race: this stream's listener
  /// can still be open for a moment after the user logs out (widget not
  /// torn down yet), so Firestore re-evaluates security rules against a
  /// now-null auth token and reports `permission-denied`. That's expected
  /// SDK behaviour, not a rules problem — we treat it as "nothing to show"
  /// rather than surfacing a scary error to an already-logged-out user.
  Stream<List<VolunteerSpHistory>> getMySPHistory(String userId) async* {
    if (userId.isEmpty) {
      yield [];
      return;
    }

    QuerySnapshot<Map<String, dynamic>> query;
    try {
      query = await firestore
          .collection('volunteers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        yield [];
        return;
      }
      rethrow;
    }

    if (query.docs.isEmpty) {
      yield [];
      return;
    }

    final volunteerId = query.docs.first.id;

    try {
      await for (final snapshot
          in firestore
              .collection('volunteer_sp_history')
              .where('volunteerId', isEqualTo: volunteerId)
              .orderBy('createdAt', descending: true)
              .snapshots()) {
        yield snapshot.docs
            .map((doc) => VolunteerSpHistory.fromFirestore(doc))
            .toList();
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        yield [];
        return;
      }
      rethrow;
    }
  }

  /// Edits only the `reason` text of an existing SP history entry (an
  /// issue at SP 1/2/3, or an undo). Nothing else about that entry —
  /// level, action, date, performedBy — is touched; this exists purely to
  /// correct or clarify wording after the fact.
  Future<void> updateSPHistoryReason(String historyId, String reason) async {
    await firestore.collection('volunteer_sp_history').doc(historyId).update({
      'reason': reason,
    });
  }

  // Get volunteer by ID
  Future<Volunteer> getVolunteerById(String id) async {
    final doc = await firestore.collection('volunteers').doc(id).get();

    if (!doc.exists) {
      throw Exception('Volunteer not found');
    }

    return Volunteer.fromFirestore(doc);
  }

  // Toggle volunteer's PIC status
  Future<void> toggleVolunteerPIC(
    String id,
    bool currentStatus,
    String tim,
  ) async {
    if (!currentStatus) {
      final batch = firestore.batch();

      // Set all volunteers in the same tim to isPIC: false
      final query = await firestore
          .collection('volunteers')
          .where('tim', isEqualTo: tim)
          .get();

      for (var doc in query.docs) {
        batch.update(doc.reference, {'isPIC': false});
      }

      // Set the selected volunteer to isPIC: true
      final selectedRef = firestore.collection('volunteers').doc(id);
      batch.update(selectedRef, {'isPIC': true});

      await batch.commit();
    } else {
      await firestore.collection('volunteers').doc(id).update({'isPIC': false});
    }
  }

  /// Clears `userId` on any volunteer doc(s) linked to [userId]. Called when
  /// a user account is deleted, so the volunteer becomes selectable again in
  /// the "Add Volunteer Account" picker instead of staying orphaned-linked.
  Future<void> unlinkVolunteerByUserId(String userId) async {
    final snapshot = await firestore
        .collection('volunteers')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'userId': FieldValue.delete()});
    }
  }

  // ── Account-linking helpers ─────────────────────────────────────────────

  /// Volunteers that don't yet have a Firebase Auth account linked
  /// (`userId` missing or empty). Used to populate the picker when creating
  /// a new volunteer login account, so linking is explicit — never guessed
  /// from name matching.
  Stream<List<Map<String, dynamic>>> getUnlinkedVolunteers() {
    return firestore.collection('volunteers').snapshots().map((snapshot) {
      final unlinked = snapshot.docs
          .where((doc) {
            final userId = (doc.data()['userId'] ?? '').toString().trim();
            return userId.isEmpty;
          })
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'namaLengkap': (data['namaLengkap'] ?? '').toString(),
              'tim': (data['tim'] ?? '').toString(),
            };
          })
          .toList();

      unlinked.sort(
        (a, b) =>
            (a['namaLengkap'] as String).compareTo(b['namaLengkap'] as String),
      );
      return unlinked;
    });
  }

  /// Sets `userId` on a volunteer document — the explicit link between a
  /// `volunteers` record and its Firebase Auth account / `users` document.
  Future<void> linkVolunteerToUser(String volunteerId, String userId) async {
    await firestore.collection('volunteers').doc(volunteerId).update({
      'userId': userId,
    });
  }

  // Search volunteers (client-side substring match — works for any part of the name)
  Stream<List<Volunteer>> searchVolunteer(
    String query,
    String? tim,
    String? jenisKelamin,
  ) {
    final lowerQuery = query.trim().toLowerCase();

    return firestore.collection('volunteers').snapshots().map((snapshot) {
      var volunteers = snapshot.docs
          .map((doc) => Volunteer.fromFirestore(doc))
          .toList();

      if (lowerQuery.isNotEmpty) {
        volunteers = volunteers
            .where((v) => v.namaLengkap.toLowerCase().contains(lowerQuery))
            .toList();
      }

      if (tim != null && tim.isNotEmpty) {
        volunteers = volunteers.where((v) => v.tim == tim).toList();
      }

      if (jenisKelamin != null && jenisKelamin.isNotEmpty) {
        volunteers = volunteers
            .where((v) => v.jenisKelamin == jenisKelamin)
            .toList();
      }

      return volunteers;
    });
  }

  // Filter volunteers by tim and jenisKelamin
  Stream<List<Volunteer>> filterVolunteer({String? tim, String? jenisKelamin}) {
    Query query = firestore.collection('volunteers');

    if (tim != null && tim.isNotEmpty) {
      query = query.where('tim', isEqualTo: tim);
    }

    if (jenisKelamin != null && jenisKelamin.isNotEmpty) {
      query = query.where('jenisKelamin', isEqualTo: jenisKelamin);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Volunteer.fromFirestore(doc)).toList(),
    );
  }
}
