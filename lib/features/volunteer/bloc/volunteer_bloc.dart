import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/firebase_crud_error.dart';
import 'volunteer_event.dart';
import 'volunteer_state.dart';
import '../data/repositories/volunteer_repository.dart';

class VolunteerBloc extends Bloc<VolunteerEvent, VolunteerState> {
  final VolunteerRepository repository;
  Timer? _debounce;

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
      _debounce?.cancel();

      final completer = Completer<void>();

      _debounce = Timer(const Duration(milliseconds: 500), () async {
        if (emit.isDone) return;

        if (event.query.isEmpty) {
          add(LoadVolunteer());
          completer.complete();
          return;
        }

        if (!emit.isDone) {
          emit(VolunteerLoading());
        }

        await emit.forEach(
          repository.searchVolunteer(event.query),
          onData: (data) => VolunteerLoaded(data),
        );

        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await completer.future;
    });
  }
}
