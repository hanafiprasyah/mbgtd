import 'package:cloud_firestore/cloud_firestore.dart';

class KitchenModel {
  final String id; // Doc ID -> also used as kitchenId (tenant key)
  final String name;
  final String ketua;
  final String idKetua;
  final String address;
  final String? ketuaWaNumb; // Head/SPPI WhatsApp number, optional

  const KitchenModel({
    required this.id,
    required this.name,
    required this.ketua,
    required this.idKetua,
    required this.address,
    this.ketuaWaNumb,
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
      ketuaWaNumb: data['ketua_wa_numb'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ketua': ketua,
      'id_ketua': idKetua,
      'address': address,
      'ketua_wa_numb': ketuaWaNumb,
    };
  }

  KitchenModel copyWith({
    String? id,
    String? name,
    String? ketua,
    String? idKetua,
    String? address,
    String? ketuaWaNumb,
  }) {
    return KitchenModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ketua: ketua ?? this.ketua,
      idKetua: idKetua ?? this.idKetua,
      address: address ?? this.address,
      ketuaWaNumb: ketuaWaNumb ?? this.ketuaWaNumb,
    );
  }
}
