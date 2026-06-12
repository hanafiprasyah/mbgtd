import 'login_event.dart';
import 'login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/authentication/data/repositories/auth_repository.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;

  LoginBloc(this.authRepository) : super(const LoginState()) {
    // Handle the LoginSubmitted event
    on<LoginSubmitted>((event, emit) async {
      // Set loading state and clear previous errors
      emit(state.copyWith(isLoading: true, error: null));

      try {
        await authRepository.login(event.email, event.password);
        emit(state.copyWith(isLoading: false));
      } catch (e) {
        emit(
          state.copyWith(isLoading: false, error: "Invalid email or password"),
        );
      }
    });
  }
}
