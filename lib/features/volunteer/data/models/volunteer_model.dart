import 'package:cloud_firestore/cloud_firestore.dart';

class Volunteer {
  final String id;
  final String namaLengkap;
  final DateTime tanggalLahir;
  final String alamat;
  final String jenisKelamin;
  final String tim;

  Volunteer({
    required this.id,
    required this.namaLengkap,
    required this.tanggalLahir,
    required this.alamat,
    required this.jenisKelamin,
    required this.tim,
  });

  factory Volunteer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Volunteer(
      id: doc.id,
      namaLengkap: data['namaLengkap'],
      tanggalLahir: (data['tanggalLahir'] as Timestamp).toDate(),
      alamat: data['alamat'],
      jenisKelamin: data['jenisKelamin'],
      tim: data['tim'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaLengkap': namaLengkap,
      'tanggalLahir': tanggalLahir,
      'alamat': alamat,
      'jenisKelamin': jenisKelamin,
      'tim': tim,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
