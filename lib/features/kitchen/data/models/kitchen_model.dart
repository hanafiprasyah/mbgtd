import 'package:cloud_firestore/cloud_firestore.dart';

class KitchenModel {
  final String id; // Doc ID -> dipakai juga sebagai kitchenId (tenant key)
  final String name;
  final String ketua;
  final String idKetua;
  final String address;

  const KitchenModel({
    required this.id,
    required this.name,
    required this.ketua,
    required this.idKetua,
    required this.address,
  });

  factory KitchenModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return KitchenModel(
      id: doc.id,
      name: data['name'] ?? '',
      ketua: data['ketua'] ?? '',
      idKetua: data['id_ketua'] ?? '',
      address: data['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ketua': ketua,
      'id_ketua': idKetua,
      'address': address,
    };
  }

  KitchenModel copyWith({
    String? id,
    String? name,
    String? ketua,
    String? idKetua,
    String? address,
  }) {
    return KitchenModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ketua: ketua ?? this.ketua,
      idKetua: idKetua ?? this.idKetua,
      address: address ?? this.address,
    );
  }
}
