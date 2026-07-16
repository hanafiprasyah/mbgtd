import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mbg_test/firebase_options.dart';

/// A Firebase Auth account just created for a volunteer, held open on the
/// secondary app instance so the caller can decide whether to keep it
/// ([confirm]) or undo it ([rollback]) after attempting the Firestore
/// writes that depend on it.
class VolunteerAuthAccount {
  final String uid;
  final User _firebaseUser;
  final FirebaseAuth _secondaryAuth;

  VolunteerAuthAccount(this.uid, this._firebaseUser, this._secondaryAuth);

  /// Call once the `users` document and the `volunteers` link have been
  /// written successfully. Just releases the secondary session — the
  /// account stays created.
  Future<void> confirm() async {
    await _secondaryAuth.signOut();
  }

  /// Call if a later step (writing to Firestore, linking the volunteer)
  /// failed. Deletes the just-created Auth account so we never leave an
  /// orphaned login with no matching `users`/`volunteers` record, then
  /// releases the secondary session.
  Future<void> rollback() async {
    try {
      await _firebaseUser.delete();
    } finally {
      await _secondaryAuth.signOut();
    }
  }
}

/// Creates Firebase Authentication accounts for volunteers WITHOUT
/// disturbing the admin's own signed-in session.
///
/// Firebase's client SDK automatically signs in as whichever user
/// `createUserWithEmailAndPassword` just created. Calling that on the
/// default [FirebaseAuth.instance] would kick the admin out of their own
/// session mid-task. To avoid that, this service spins up a second,
/// isolated [FirebaseApp] (same project, same config) purely to create the
/// new account. The admin's session on the default app/instance is never
/// touched.
class VolunteerAuthService {
  static const String _secondaryAppName = 'volunteer_creation';

  Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app(_secondaryAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  /// Creates the Auth account and returns a handle to it. The caller MUST
  /// call either `.confirm()` or `.rollback()` on the result — never leave
  /// it dangling, or the secondary session (and, if unconfirmed, the
  /// orphaned account) will linger.
  Future<VolunteerAuthAccount> createAuthAccount({
    required String email,
    required String password,
  }) async {
    final app = await _secondaryApp();
    final auth = FirebaseAuth.instanceFor(app: app);

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        await auth.signOut();
        throw Exception('Failed to create account: no UID returned.');
      }
      return VolunteerAuthAccount(user.uid, user, auth);
    } on FirebaseAuthException catch (e) {
      await auth.signOut();
      throw Exception(_mapAuthError(e));
    }
  }

  /// Generates a random password suitable for sharing with a volunteer
  /// (they can change it later from within the app, if that flow exists).
  String generateRandomPassword({int length = 12}) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered in Firebase Authentication.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters).';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project.';
      default:
        return e.message ?? 'Failed to create the login account.';
    }
  }
}
