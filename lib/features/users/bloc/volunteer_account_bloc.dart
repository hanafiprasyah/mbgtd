import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/users/data/repositories/volunteer_account_repository.dart';
import 'volunteer_account_event.dart';
import 'volunteer_account_state.dart';

class VolunteerAccountBloc
    extends Bloc<VolunteerAccountEvent, VolunteerAccountState> {
  final VolunteerAccountRepository repository;

  VolunteerAccountBloc({VolunteerAccountRepository? repository})
    : repository = repository ?? VolunteerAccountRepository(),
      super(VolunteerAccountInitial()) {
    on<SubmitVolunteerAccount>((event, emit) async {
      emit(VolunteerAccountSubmitting());
      try {
        final user = await this.repository.createVolunteerAccount(
          volunteerId: event.volunteerId,
          email: event.email,
          password: event.password,
          fullname: event.fullname,
          username: event.username,
        );
        emit(VolunteerAccountSuccess(user));
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        emit(VolunteerAccountError(message));
      }
    });
  }
}
