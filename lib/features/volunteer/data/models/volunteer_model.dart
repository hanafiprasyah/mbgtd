import 'package:cloud_firestore/cloud_firestore.dart';

class Volunteer {
  final String id;
  final String namaLengkap;
  final String namaSearch;
  final DateTime tanggalLahir;
  final String alamat;
  final String jenisKelamin;
  final String tim;

  Volunteer({
    required this.id,
    required this.namaLengkap,
    required this.namaSearch,
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
      namaSearch:
          data['namaSearch'] ?? (data['namaLengkap'] as String).toLowerCase(),
      tanggalLahir: (data['tanggalLahir'] as Timestamp).toDate(),
      alamat: data['alamat'],
      jenisKelamin: data['jenisKelamin'],
      tim: data['tim'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaLengkap': namaLengkap,
      'namaSearch': namaLengkap.toLowerCase(),
      'tanggalLahir': tanggalLahir,
      'alamat': alamat,
      'jenisKelamin': jenisKelamin,
      'tim': tim,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Volunteer copyWith({
    String? id,
    String? namaLengkap,
    String? namaSearch,
    DateTime? tanggalLahir,
    String? alamat,
    String? jenisKelamin,
    String? tim,
  }) {
    return Volunteer(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      namaSearch: namaSearch ?? this.namaSearch,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      alamat: alamat ?? this.alamat,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      tim: tim ?? this.tim,
    );
  }
}
