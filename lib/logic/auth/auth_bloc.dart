import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  late final StreamSubscription _userSub;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    // listen to global auth state
    _userSub = authRepository.user.listen((user) {
      add(AuthUserChanged(user != null));
    });

    on<AuthUserChanged>((event, emit) {
      if (event.isLoggedIn) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<AuthCheckRequested>((event, emit) async {
      final hasToken = await authRepository.hasToken();

      if (hasToken) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLoggedOut>((event, emit) async {
      await authRepository.logout();
    });
  }

  @override
  Future<void> close() {
    _userSub.cancel();
    return super.close();
  }
}
