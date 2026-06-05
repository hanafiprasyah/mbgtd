import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Stream<List<UserModel>> getUsers({String? role}) {
    final query = role != null && role.isNotEmpty
        ? _usersCollection.where('role', isEqualTo: role)
        : _usersCollection;

    return query.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
      users.sort((a, b) => a.fullname.compareTo(b.fullname));
      return users;
    });
  }

  Stream<List<UserModel>> searchUsers(String query, {String? role}) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return getUsers(role: role);
    }

    return getUsers(role: role).map((users) {
      return users.where((user) {
        final email = user.email.toLowerCase();
        final fullname = user.fullname.toLowerCase();
        final roleName = user.role.toLowerCase();
        final username = user.username.toLowerCase();
        return email.contains(normalized) ||
            fullname.contains(normalized) ||
            roleName.contains(normalized) ||
            username.contains(normalized);
      }).toList();
    });
  }

  Future<UserModel> getUserById(String id) async {
    final doc = await _usersCollection.doc(id).get();
    if (!doc.exists) {
      throw Exception('User not found');
    }
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> addUser(UserModel user) async {
    final docRef = user.id.isNotEmpty
        ? _usersCollection.doc(user.id)
        : _usersCollection.doc();
    final created = user.id.isEmpty ? user.copyWith(id: docRef.id) : user;
    await docRef.set(created.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    if (user.id.isEmpty) {
      throw Exception('User id is required for update');
    }
    await _usersCollection.doc(user.id).update(user.toMap());
  }

  Future<void> deleteUser(String id) async {
    await _usersCollection.doc(id).delete();
  }
}
