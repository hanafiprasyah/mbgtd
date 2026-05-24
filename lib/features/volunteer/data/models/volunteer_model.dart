import 'package:cloud_firestore/cloud_firestore.dart';

class Volunteer {
  final String id;
  final String namaLengkap;
  final String namaSearch;
  final DateTime tanggalLahir;
  final String alamat;
  final String jenisKelamin;
  final String tim;
  final bool isActive;
  final String? noRek;
  final String? namaBank;

  Volunteer({
    required this.id,
    required this.namaLengkap,
    required this.namaSearch,
    required this.tanggalLahir,
    required this.alamat,
    required this.jenisKelamin,
    required this.tim,
    required this.isActive,
    this.noRek = '',
    this.namaBank = '',
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
      isActive: data['isActive'] ?? true,
      noRek: data['noRek'] ?? '',
      namaBank: data['namaBank'] ?? '',
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
      'isActive': isActive,
      'noRek': noRek,
      'namaBank': namaBank,
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
    required bool isActive,
    String? noRek,
    String? namaBank,
  }) {
    return Volunteer(
      id: id ?? this.id,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      namaSearch: namaSearch ?? this.namaSearch,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      alamat: alamat ?? this.alamat,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      tim: tim ?? this.tim,
      isActive: isActive,
      noRek: noRek,
      namaBank: namaBank,
    );
  }
}
