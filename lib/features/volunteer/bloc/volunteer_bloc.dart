// import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/firebase_crud_error.dart';
import 'volunteer_event.dart';
import 'volunteer_state.dart';
import '../data/repositories/volunteer_repository.dart';
import 'package:rxdart/rxdart.dart';

class VolunteerBloc extends Bloc<VolunteerEvent, VolunteerState> {
  final VolunteerRepository repository;

  EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) =>
        events.distinct().debounceTime(duration).switchMap(mapper);
  }

  VolunteerBloc(this.repository) : super(VolunteerInitial()) {
    on<LoadVolunteer>((event, emit) async {
      emit(VolunteerLoading());
      await emit.forEach(
        repository.getVolunteer(),
        onData: (data) => VolunteerLoaded(data),
      );
    });

    on<AddVolunteer>((event, emit) async {
      emit(VolunteerLoading());
      try {
        await repository.addVolunteer(event.volunteer);
        emit(VolunteerSuccess(event.volunteer));
      } catch (e) {
        emit(VolunteerError(mapFirebaseError(e)));
      }
    });

    on<UpdateVolunteer>((event, emit) async {
      emit(VolunteerLoading());
      try {
        await repository.updateVolunteer(event.volunteer);
        emit(VolunteerSuccess(event.volunteer));
      } catch (e) {
        emit(VolunteerError(mapFirebaseError(e)));
      }
    });

    on<DeleteVolunteer>((event, emit) async {
      emit(VolunteerLoading());
      try {
        await repository.deleteVolunteer(event.id);
        emit(VolunteerSuccess(null));
      } catch (e) {
        emit(VolunteerError(mapFirebaseError(e)));
      }
    });

    on<SearchVolunteer>((event, emit) async {
      // If no search text and no filter → fallback to all data
      final hasFilter =
          (event.tim != null && event.tim!.isNotEmpty) ||
          (event.jenisKelamin != null && event.jenisKelamin!.isNotEmpty);

      if (event.query.isEmpty && !hasFilter) {
        add(LoadVolunteer());
        return;
      }

      emit(VolunteerLoading());

      await emit.forEach(
        repository.searchVolunteer(event.query, event.tim, event.jenisKelamin),
        onData: (data) => VolunteerLoaded(data),
      );
    }, transformer: debounce(const Duration(milliseconds: 800)));

    on<FilterVolunteer>((event, emit) async {
      emit(VolunteerLoading());

      await emit.forEach(
        repository.filterVolunteer(
          tim: event.tim,
          jenisKelamin: event.jenisKelamin,
        ),
        onData: (data) => VolunteerLoaded(data),
      );
    });

    on<ToggleVolunteerStatus>((event, emit) async {
      try {
        await repository.toggleVolunteerStatus(event.id, event.currentStatus);
      } catch (e) {
        emit(VolunteerError(e.toString()));
      }
    });
  }
}
