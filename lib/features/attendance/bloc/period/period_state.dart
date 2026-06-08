import 'package:mbg_test/features/attendance/data/models/attendance_period.dart';

abstract class PeriodHistoryState {}

class PeriodHistoryInitial extends PeriodHistoryState {}

class PeriodHistoryLoading extends PeriodHistoryState {}

class PeriodHistoryLoaded extends PeriodHistoryState {
  final List<AttendancePeriod> periods;
  PeriodHistoryLoaded(this.periods);
}

class PeriodHistoryError extends PeriodHistoryState {
  final String message;
  PeriodHistoryError(this.message);
}
