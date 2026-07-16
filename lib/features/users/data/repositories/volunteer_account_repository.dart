import 'package:mbg_test/features/users/data/models/user_model.dart';
import 'package:mbg_test/features/users/data/repositories/user_repository.dart';
import 'package:mbg_test/features/users/data/services/volunteer_auth_service.dart';
import 'package:mbg_test/features/volunteer/data/repositories/volunteer_repository.dart';

/// Runs the entire "give this volunteer app login access" flow in one call:
///
///  1. Create a Firebase Authentication account (email/password) — via a
///     secondary Firebase App so the admin's own session is untouched.
///  2. Write a `users/{uid}` document with role `volunteer`.
///  3. Set `userId = uid` on the chosen `volunteers/{volunteerId}` document.
///
/// If step 2 or 3 fails, the Auth account created in step 1 is rolled back
/// (deleted) so no orphaned login is left behind.
class VolunteerAccountRepository {
  final UserRepository _userRepository;
  final VolunteerRepository _volunteerRepository;
  final VolunteerAuthService _authService;

  VolunteerAccountRepository({
    UserRepository? userRepository,
    VolunteerRepository? volunteerRepository,
    VolunteerAuthService? authService,
  }) : _userRepository = userRepository ?? UserRepository(),
       _volunteerRepository = volunteerRepository ?? VolunteerRepository(),
       _authService = authService ?? VolunteerAuthService();

  Future<UserModel> createVolunteerAccount({
    required String volunteerId,
    required String email,
    required String password,
    required String fullname,
    required String username,
  }) async {
    final account = await _authService.createAuthAccount(
      email: email,
      password: password,
    );

    final user = UserModel(
      id: account.uid,
      email: email.trim(),
      fullname: fullname.trim(),
      role: 'volunteer',
      username: username.trim(),
    );

    try {
      await _userRepository.addUser(user);
      await _volunteerRepository.linkVolunteerToUser(volunteerId, account.uid);
    } catch (_) {
      await account.rollback();
      rethrow;
    }

    await account.confirm();
    return user;
  }
}
