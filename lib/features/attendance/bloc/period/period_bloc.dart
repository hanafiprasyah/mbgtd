import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/attendance/bloc/period/period_event.dart';
import 'package:mbg_test/features/attendance/bloc/period/period_state.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_repository.dart';

class PeriodHistoryBloc extends Bloc<PeriodHistoryEvent, PeriodHistoryState> {
  final AttendanceRepository repository;

  PeriodHistoryBloc(this.repository) : super(PeriodHistoryInitial()) {
    on<LoadPeriodHistory>(_onLoad);
    on<RefreshPeriodHistory>(_onRefresh);
  }

  Future<void> _onLoad(LoadPeriodHistory event, Emitter emit) async {
    emit(PeriodHistoryLoading());
    try {
      final periods = await repository.getAttendancePeriods();
      emit(PeriodHistoryLoaded(periods));
    } catch (e) {
      emit(PeriodHistoryError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshPeriodHistory event, Emitter emit) async {
    try {
      final periods = await repository.getAttendancePeriods();
      emit(PeriodHistoryLoaded(periods));
    } catch (e) {
      emit(PeriodHistoryError(e.toString()));
    }
  }
}
