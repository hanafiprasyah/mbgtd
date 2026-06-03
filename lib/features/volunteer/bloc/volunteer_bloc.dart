// import 'dart:async';
import 'volunteer_event.dart';
import 'volunteer_state.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/firebase_crud_error.dart';
import 'package:mbg_test/features/volunteer/data/repositories/volunteer_repository.dart';

class VolunteerBloc extends Bloc<VolunteerEvent, VolunteerState> {
  final VolunteerRepository repository;

  // Debounce transformer for search events to prevent excessive calls
  EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) =>
        events.distinct().debounceTime(duration).switchMap(mapper);
  }

  VolunteerBloc(this.repository) : super(VolunteerInitial()) {
    // Load all volunteers
    on<LoadVolunteer>((event, emit) async {
      emit(VolunteerLoading());
      await emit.forEach(
        repository.getVolunteer(),
        onData: (data) => VolunteerLoaded(data),
      );
    });

    // Add a new volunteer
    on<AddVolunteer>((event, emit) async {
      emit(VolunteerLoading());
      try {
        await repository.addVolunteer(event.volunteer);
        emit(VolunteerSuccess(event.volunteer));
      } catch (e) {
        emit(VolunteerError(mapFirebaseError(e)));
      }
    });

    // Update an existing volunteer
    on<UpdateVolunteer>((event, emit) async {
      emit(VolunteerLoading());
      try {
        await repository.updateVolunteer(event.volunteer);
        emit(VolunteerSuccess(event.volunteer));
      } catch (e) {
        emit(VolunteerError(mapFirebaseError(e)));
      }
    });

    // Delete a volunteer
    on<DeleteVolunteer>((event, emit) async {
      emit(VolunteerLoading());
      try {
        await repository.deleteVolunteer(event.id);
        emit(VolunteerSuccess(null));
      } catch (e) {
        emit(VolunteerError(mapFirebaseError(e)));
      }
    });

    // Search volunteers with optional filters (debounced)
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

    // Filter volunteers
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

    // Toggle volunteer active status
    on<ToggleVolunteerStatus>((event, emit) async {
      try {
        await repository.toggleVolunteerStatus(event.id, event.currentStatus);
      } catch (e) {
        emit(VolunteerError(e.toString()));
      }
    });

    // Get volunteer details by ID
    on<GetVolunteerById>((event, emit) async {
      emit(VolunteerLoading());
      try {
        final volunteer = await repository.getVolunteerById(event.id);
        emit(VolunteerDetailLoaded(volunteer));
      } catch (e) {
        emit(VolunteerError(mapFirebaseError(e)));
      }
    });

    // Toggle volunteer PIC status
    on<ToggleVolunteerPIC>((event, emit) async {
      try {
        await repository.toggleVolunteerPIC(
          event.id,
          event.currentStatus,
          event.tim,
        );

        final updated = await repository.getVolunteerById(event.id);
        emit(VolunteerDetailLoaded(updated));
      } catch (e) {
        emit(VolunteerError(e.toString()));
      }
    });
  }
}
