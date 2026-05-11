import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/volunteer_model.dart';

class VolunteerRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<List<Volunteer>> getVolunteer() {
    return firestore
        .collection('volunteers')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Volunteer.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Volunteer>> searchVolunteer(String query) {
    return firestore
        .collection('volunteers')
        .where('namaSearch', isGreaterThanOrEqualTo: query.toLowerCase())
        .where(
          'namaSearch',
          isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff',
        )
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Volunteer.fromFirestore(doc)).toList(),
        );
  }

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

  Future<void> addVolunteer(Volunteer volunteer) async {
    await firestore.collection('volunteers').add(volunteer.toMap());
  }

  Future<void> updateVolunteer(Volunteer volunteer) async {
    await firestore
        .collection('volunteers')
        .doc(volunteer.id)
        .update(volunteer.toMap());
  }

  Future<void> deleteVolunteer(String id) async {
    await firestore.collection('volunteers').doc(id).delete();
  }
}
