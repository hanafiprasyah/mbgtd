import 'dart:async';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/services/token_service.dart';
import 'package:mbg_test/core/services/isolate_scheduler.dart';
import 'package:mbg_test/data/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // The AuthBloc manages authentication state and token refresh logic.
  final AuthRepository authRepository;
  final IsolateScheduler scheduler = IsolateScheduler();
  final TokenService tokenService = TokenService();
  late final StreamSubscription _userSub;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    _userSub = authRepository.user.listen((user) {
      add(AuthUserChanged(user != null));
    });

    // Listen for authentication state changes and update the state accordingly.
    on<AuthUserChanged>((event, emit) async {
      if (event.isLoggedIn) {
        // start smart refresh loop
        await _startSmartRefreshLoop();
        emit(AuthAuthenticated());
      } else {
        scheduler.stop();
        emit(AuthUnauthenticated());
      }
    });

    // Handle logout event by calling the logout method in the repository.
    on<AuthLoggedOut>((event, emit) async {
      await authRepository.logout();
    });

    // Check for existing token on app start and update state accordingly.
    on<AuthCheckRequested>((event, emit) async {
      final hasToken = await authRepository.hasToken();
      if (hasToken) {
        add(AuthUserChanged(true));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  // Starts a loop to refresh the token before it expires. It calculates the next refresh duration and schedules a task to refresh the token. If the refresh is successful, it reschedules based on the new token's expiry.
  Future<void> _startSmartRefreshLoop() async {
    final duration = await tokenService.getNextRefreshDuration();
    await scheduler.start(duration);
    scheduler.onTick = () async {
      final success = await tokenService.refreshTokenWithRetry();
      if (success) {
        // re-schedule based on a new expiry
        await _startSmartRefreshLoop();
      }
    };
  }

  @override
  Future<void> close() {
    _userSub.cancel();
    scheduler.stop();
    return super.close();
  }
}
