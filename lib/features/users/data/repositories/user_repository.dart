import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/features/volunteer/data/repositories/volunteer_repository.dart';
import '../models/user_model.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;
  final VolunteerRepository _volunteerRepository;

  UserRepository({VolunteerRepository? volunteerRepository})
    : _volunteerRepository = volunteerRepository ?? VolunteerRepository();

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

  /// Deletes the `users/{id}` document, and — if that user's role was
  /// `volunteer` — also clears the matching `volunteers.userId` link so the
  /// volunteer record doesn't stay pointing at a deleted account.
  ///
  /// NOTE: this does NOT delete the Firebase Authentication account itself.
  /// The client SDK can only delete the currently signed-in user, never an
  /// arbitrary other user — that requires the Firebase Admin SDK (a Cloud
  /// Function). See `functions/deleteUserAccount` if you've set that up;
  /// otherwise the Auth login must be removed manually from the Firebase
  /// Console after this completes.
  Future<void> deleteUser(String id) async {
    // Look up the user first (while the doc still exists) so we know
    // whether volunteer-link cleanup is needed. If the lookup fails for any
    // reason, we still proceed with deleting the doc — just skip cleanup.
    UserModel? user;
    try {
      user = await getUserById(id);
    } catch (_) {
      user = null;
    }

    await _usersCollection.doc(id).delete();

    if (user != null && user.role.trim().toLowerCase() == 'volunteer') {
      try {
        await _volunteerRepository.unlinkVolunteerByUserId(id);
      } catch (_) {
        // Consider surfacing this via your logging tool so an admin can
        // clean up the stale link manually if it ever happens.
      }
    }
  }
}
