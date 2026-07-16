import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';

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

  // Search volunteers
  Stream<List<Volunteer>> searchVolunteer(
    String query,
    String? tim,
    String? jenisKelamin,
  ) {
    Query q = firestore.collection('volunteers');

    if (query.isNotEmpty) {
      // Assuming 'namaSearch' is a field in Firestore that contains the lowercase version of the volunteer's name for search purposes
      q = q
          .where('namaSearch', isGreaterThanOrEqualTo: query.toLowerCase())
          .where(
            'namaSearch',
            isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff',
          );
    }

    // Filter by tim if provided
    if (tim != null && tim.isNotEmpty) {
      q = q.where('tim', isEqualTo: tim);
    }

    // Filter by jenisKelamin if provided
    if (jenisKelamin != null && jenisKelamin.isNotEmpty) {
      q = q.where('jenisKelamin', isEqualTo: jenisKelamin);
    }

    return q.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Volunteer.fromFirestore(doc)).toList(),
    );
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
