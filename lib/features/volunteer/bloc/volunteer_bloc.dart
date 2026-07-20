import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/firebase_crud_error.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';
import 'package:mbg_test/features/volunteer/data/repositories/volunteer_repository.dart';
import 'package:rxdart/rxdart.dart';

import 'volunteer_event.dart';
import 'volunteer_state.dart';

class VolunteerBloc extends Bloc<VolunteerEvent, VolunteerState> {
  VolunteerBloc(this.repository) : super(VolunteerInitial()) {
    on<LoadVolunteer>(_onLoadVolunteer);
    on<SearchVolunteer>(
      _onSearchVolunteer,
      transformer: _searchTransformer(const Duration(milliseconds: 500)),
    );
    on<FilterVolunteer>(_onFilterVolunteer);
    on<VolunteerDataReceived>(_onVolunteerDataReceived);
    on<VolunteerStreamFailed>(_onVolunteerStreamFailed);
    on<AddVolunteer>(_onAddVolunteer);
    on<UpdateVolunteer>(_onUpdateVolunteer);
    on<DeleteVolunteer>(_onDeleteVolunteer);
    on<ToggleVolunteerStatus>(_onToggleVolunteerStatus);
    on<GetVolunteerById>(_onGetVolunteerById);
    on<ToggleVolunteerPIC>(_onToggleVolunteerPIC);
    on<EscalateVolunteerSP>(_onEscalateVolunteerSP);
    on<ResetVolunteerSP>(_onResetVolunteerSP);
  }

  final VolunteerRepository repository;
  StreamSubscription<List<Volunteer>>? _volunteerSubscription;

  static EventTransformer<SearchVolunteer> _searchTransformer(
    Duration duration,
  ) {
    return (events, mapper) {
      return events
          .switchMap((event) {
            final hasCriteria =
                event.query.trim().isNotEmpty ||
                (event.tim?.isNotEmpty ?? false) ||
                (event.jenisKelamin?.isNotEmpty ?? false);

            return hasCriteria
                ? Rx.timer(event, duration)
                : Stream.value(event);
          })
          .switchMap(mapper);
    };
  }

  Future<void> _onLoadVolunteer(
    LoadVolunteer event,
    Emitter<VolunteerState> emit,
  ) async {
    await _watchVolunteerStream(repository.getVolunteer(), emit);
  }

  Future<void> _onSearchVolunteer(
    SearchVolunteer event,
    Emitter<VolunteerState> emit,
  ) async {
    final query = event.query.trim();
    final hasFilter =
        (event.tim?.isNotEmpty ?? false) ||
        (event.jenisKelamin?.isNotEmpty ?? false);

    if (query.isEmpty && !hasFilter) {
      add(LoadVolunteer());
      return;
    }

    await _watchVolunteerStream(
      repository.searchVolunteer(query, event.tim, event.jenisKelamin),
      emit,
    );
  }

  Future<void> _onFilterVolunteer(
    FilterVolunteer event,
    Emitter<VolunteerState> emit,
  ) async {
    final hasFilter =
        (event.tim?.isNotEmpty ?? false) ||
        (event.jenisKelamin?.isNotEmpty ?? false);

    if (!hasFilter) {
      add(LoadVolunteer());
      return;
    }

    await _watchVolunteerStream(
      repository.filterVolunteer(
        tim: event.tim,
        jenisKelamin: event.jenisKelamin,
      ),
      emit,
    );
  }

  void _onVolunteerDataReceived(
    VolunteerDataReceived event,
    Emitter<VolunteerState> emit,
  ) {
    emit(VolunteerLoaded(event.volunteer));
  }

  void _onVolunteerStreamFailed(
    VolunteerStreamFailed event,
    Emitter<VolunteerState> emit,
  ) {
    emit(VolunteerError(mapFirebaseError(event.error)));
  }

  Future<void> _onAddVolunteer(
    AddVolunteer event,
    Emitter<VolunteerState> emit,
  ) async {
    emit(VolunteerLoading());
    try {
      await repository.addVolunteer(event.volunteer);
      emit(VolunteerSuccess(event.volunteer));
    } catch (e) {
      emit(VolunteerError(mapFirebaseError(e)));
    }
  }

  Future<void> _onUpdateVolunteer(
    UpdateVolunteer event,
    Emitter<VolunteerState> emit,
  ) async {
    emit(VolunteerLoading());
    try {
      await repository.updateVolunteer(event.volunteer);
      emit(VolunteerSuccess(event.volunteer));
    } catch (e) {
      emit(VolunteerError(mapFirebaseError(e)));
    }
  }

  Future<void> _onDeleteVolunteer(
    DeleteVolunteer event,
    Emitter<VolunteerState> emit,
  ) async {
    emit(VolunteerLoading());
    try {
      await repository.deleteVolunteer(event.id);
      emit(VolunteerSuccess(null));
    } catch (e) {
      emit(VolunteerError(mapFirebaseError(e)));
    }
  }

  Future<void> _onToggleVolunteerStatus(
    ToggleVolunteerStatus event,
    Emitter<VolunteerState> emit,
  ) async {
    try {
      await repository.toggleVolunteerStatus(event.id, event.currentStatus);
    } catch (e) {
      emit(VolunteerError(mapFirebaseError(e)));
    }
  }

  Future<void> _onGetVolunteerById(
    GetVolunteerById event,
    Emitter<VolunteerState> emit,
  ) async {
    emit(VolunteerLoading());
    try {
      final volunteer = await repository.getVolunteerById(event.id);
      emit(VolunteerDetailLoaded(volunteer));
    } catch (e) {
      emit(VolunteerError(mapFirebaseError(e)));
    }
  }

  Future<void> _onToggleVolunteerPIC(
    ToggleVolunteerPIC event,
    Emitter<VolunteerState> emit,
  ) async {
    try {
      await repository.toggleVolunteerPIC(
        event.id,
        event.currentStatus,
        event.tim,
      );

      final updated = await repository.getVolunteerById(event.id);
      emit(VolunteerDetailLoaded(updated));
    } catch (e) {
      emit(VolunteerError(mapFirebaseError(e)));
    }
  }

  Future<void> _onEscalateVolunteerSP(
    EscalateVolunteerSP event,
    Emitter<VolunteerState> emit,
  ) async {
    try {
      await repository.escalateVolunteerSP(
        event.id,
        event.currentLevel,
        event.reason,
        volunteerName: event.volunteerName,
        performedBy: _currentUserLabel(),
      );

      final updated = await repository.getVolunteerById(event.id);
      emit(VolunteerDetailLoaded(updated));
    } catch (e) {
      emit(VolunteerError(mapFirebaseError(e)));
    }
  }

  Future<void> _onResetVolunteerSP(
    ResetVolunteerSP event,
    Emitter<VolunteerState> emit,
  ) async {
    try {
      await repository.resetVolunteerSP(
        event.id,
        event.currentLevel,
        event.reason,
        volunteerName: event.volunteerName,
        performedBy: _currentUserLabel(),
      );

      final updated = await repository.getVolunteerById(event.id);
      emit(VolunteerDetailLoaded(updated));
    } catch (e) {
      emit(VolunteerError(mapFirebaseError(e)));
    }
  }

  String? _currentUserLabel() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.email ?? user.uid;
  }

  Future<void> _watchVolunteerStream(
    Stream<List<Volunteer>> stream,
    Emitter<VolunteerState> emit,
  ) async {
    await _volunteerSubscription?.cancel();
    emit(VolunteerLoading());

    _volunteerSubscription = stream.listen(
      (volunteer) => add(VolunteerDataReceived(volunteer)),
      onError: (Object error) => add(VolunteerStreamFailed(error)),
    );
  }

  @override
  Future<void> close() async {
    await _volunteerSubscription?.cancel();
    return super.close();
  }
}
