import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/features/kitchen/data/models/kitchen_model.dart';

class KitchenRepository {
  final CollectionReference<Map<String, dynamic>> _collection;

  KitchenRepository({FirebaseFirestore? firestore})
    : _collection = (firestore ?? FirebaseFirestore.instance).collection(
        'kitchens',
      );

  Stream<List<KitchenModel>> getKitchens() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KitchenModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<KitchenModel?> getKitchenById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return KitchenModel.fromFirestore(doc);
  }

  /// Streams a single kitchen document in real time, so the detail page
  /// stays in sync automatically after edits (no manual refresh needed).
  Stream<KitchenModel?> streamKitchenById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return KitchenModel.fromFirestore(doc);
    });
  }

  /// Checks whether a doc ID is already taken. This matters because the ID
  /// doubles as the kitchenId/tenant key used across other collections.
  Future<bool> isIdTaken(String id) async {
    final doc = await _collection.doc(id).get();
    return doc.exists;
  }

  /// Creates a new kitchen with a custom document ID (not auto-generated),
  /// so the ID can be reused as the kitchenId in other features later.
  Future<void> addKitchen(KitchenModel kitchen) async {
    if (kitchen.id.trim().isEmpty) {
      throw Exception('Doc ID cannot be empty.');
    }
    final taken = await isIdTaken(kitchen.id);
    if (taken) {
      throw Exception('ID "${kitchen.id}" is already used by another kitchen.');
    }
    await _collection.doc(kitchen.id).set(kitchen.toMap());
  }

  Future<void> updateKitchen(KitchenModel kitchen) async {
    await _collection.doc(kitchen.id).update(kitchen.toMap());
  }

  Future<void> deleteKitchen(String id) async {
    await _collection.doc(id).delete();
  }
}
