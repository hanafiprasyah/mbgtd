import 'package:flutter_bloc/flutter_bloc.dart';
import 'volunteer_event.dart';
import 'volunteer_state.dart';
import '../data/repositories/volunteer_repository.dart';

class VolunteerBloc extends Bloc<VolunteerEvent, VolunteerState> {
  final VolunteerRepository repository;

  VolunteerBloc(this.repository) : super(VolunteerInitial()) {
    on<LoadVolunteer>((event, emit) async {
      emit(VolunteerLoading());
      await emit.forEach(
        repository.getVolunteer(),
        onData: (data) => VolunteerLoaded(data),
      );
    });

    on<AddVolunteer>((event, emit) async {
      await repository.addVolunteer(event.volunteer);
    });

    on<UpdateVolunteer>((event, emit) async {
      await repository.updateVolunteer(event.volunteer);
    });

    on<DeleteVolunteer>((event, emit) async {
      await repository.deleteVolunteer(event.id);
    });
  }
}
