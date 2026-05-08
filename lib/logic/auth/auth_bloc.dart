import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    on<AuthStarted>((event, emit) async {
      await emit.forEach(
        authRepository.user,
        onData: (user) =>
            user != null ? AuthAuthenticated() : AuthUnauthenticated(),
      );
    });

    on<AuthLoggedOut>((event, emit) async {
      await authRepository.logout();
    });
  }
}
