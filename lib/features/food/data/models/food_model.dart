import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String? id;
  final String name;
  final String periode;
  final String dibuatOleh;
  final String dimasakOleh;
  final String diketahuiOleh;
  final double karbohidrat;
  final double protein;
  final double lemak;
  final double energi;
  final double serat;
  final String? photoUrl; // URL from Cloudinary
  final DateTime? updatedAt;

  Food({
    this.id,
    required this.name,
    required this.periode,
    required this.dibuatOleh,
    required this.dimasakOleh,
    required this.diketahuiOleh,
    required this.karbohidrat,
    required this.protein,
    required this.lemak,
    required this.energi,
    required this.serat,
    this.photoUrl,
    this.updatedAt,
  });

  factory Food.fromFirestore(Map<String, dynamic> data, String docId) {
    return Food(
      id: docId,
      name: data['name'] ?? '',
      periode: data['periode'] ?? '',
      dibuatOleh: data['dibuatOleh'] ?? '',
      dimasakOleh: data['dimasakOleh'] ?? '',
      diketahuiOleh: data['diketahuiOleh'] ?? '',
      karbohidrat: (data['karbohidrat'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      lemak: (data['lemak'] ?? 0).toDouble(),
      energi: (data['energi'] ?? 0).toDouble(),
      serat: (data['serat'] ?? 0).toDouble(),
      photoUrl: data['photoUrl'],
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'periode': periode,
      'dibuatOleh': dibuatOleh,
      'dimasakOleh': dimasakOleh,
      'diketahuiOleh': diketahuiOleh,
      'karbohidrat': karbohidrat,
      'protein': protein,
      'lemak': lemak,
      'energi': energi,
      'serat': serat,
      'photoUrl': photoUrl,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
