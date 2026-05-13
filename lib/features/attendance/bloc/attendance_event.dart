abstract class AttendanceEvent {}

class ScanQR extends AttendanceEvent {
  final String qrData;
  ScanQR(this.qrData);
}
