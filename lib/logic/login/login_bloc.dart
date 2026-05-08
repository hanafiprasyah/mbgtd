import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';

import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc(this.authRepository) : super(const LoginState()) {
    on<LoginSubmitted>((event, emit) async {
      emit(state.copyWith(isLoading: true));

      try {
        await authRepository.login(event.email, event.password);
        emit(state.copyWith(isLoading: false));
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    });
  }
}
