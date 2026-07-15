import 'attendance_event.dart';
import 'attendance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/attendance/data/repositories/attendance_repository.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;
  bool isProcessing = false;

  AttendanceBloc(this.repository) : super(AttendanceInitial()) {
    // Event handler for scanning QR code
    on<ScanQR>((event, emit) async {
      if (isProcessing) return;
      isProcessing = true;

      emit(AttendanceLoading());
      try {
        final data = event.qrData.split('|');

        // Validate format QR
        if (data.length < 3) {
          emit(AttendanceError('Invalid QR format'));
          isProcessing = false;
          return;
        }

        final id = data[0].trim();
        final nama = data[1].trim();
        final tim = data[2].trim();

        // Validate QR value (avoid case "||")
        if (id.isEmpty || nama.isEmpty || tim.isEmpty) {
          emit(AttendanceError('QR data is empty / invalid'));
          isProcessing = false;
          return;
        }

        // Call repository to scan attendance
        await repository.scanAttendance(volunteerId: id, nama: nama, tim: tim);

        emit(AttendanceSuccess('Attendance recorded successfully'));
        isProcessing = false;
      } catch (e) {
        final error = e.toString();

        if (error.contains('already-scanned')) {
          emit(AttendanceError('Already scanned today'));
        } else if (error.contains('permission')) {
          emit(AttendanceError('Permission denied'));
        } else if (error.contains('user-not-logged-in')) {
          emit(AttendanceError('User not logged in'));
        } else if (error.contains('volunteer-inactive')) {
          emit(
            AttendanceError(
              'Scanning blocked because of inactive volunteer status',
            ),
          );
        } else {
          emit(AttendanceError('Failed to scan QR'));
        }

        isProcessing = false;
      }
    });
  }
}
