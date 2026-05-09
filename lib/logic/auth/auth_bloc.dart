import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/services/token_service.dart';
import '../../core/services/isolate_scheduler.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  final IsolateScheduler scheduler = IsolateScheduler();

  final TokenService tokenService = TokenService();

  late final StreamSubscription _userSub;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    _userSub = authRepository.user.listen((user) {
      add(AuthUserChanged(user != null));
    });

    on<AuthUserChanged>((event, emit) async {
      if (event.isLoggedIn) {
        // start background scheduler
        await scheduler.start();

        // connect scheduler to refresh
        scheduler.onTick = () async {
          await tokenService.refreshToken();
        };

        emit(AuthAuthenticated());
      } else {
        scheduler.stop();
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLoggedOut>((event, emit) async {
      await authRepository.logout();
    });

    on<AuthCheckRequested>((event, emit) async {
      final hasToken = await authRepository.hasToken();

      if (hasToken) {
        add(AuthUserChanged(true));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  @override
  Future<void> close() {
    _userSub.cancel();
    scheduler.stop();
    return super.close();
  }
}
