import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';

abstract class VolunteerEvent {}

class LoadVolunteer extends VolunteerEvent {}

class AddVolunteer extends VolunteerEvent {
  final Volunteer volunteer;
  AddVolunteer(this.volunteer);
}

class UpdateVolunteer extends VolunteerEvent {
  final Volunteer volunteer;
  UpdateVolunteer(this.volunteer);
}

class DeleteVolunteer extends VolunteerEvent {
  final String id;
  DeleteVolunteer(this.id);
}

class SearchVolunteer extends VolunteerEvent {
  final String query;
  final String? tim;
  final String? jenisKelamin;

  SearchVolunteer(this.query, this.tim, this.jenisKelamin);
}

class VolunteerDataReceived extends VolunteerEvent {
  final List<Volunteer> volunteer;

  VolunteerDataReceived(this.volunteer);
}

class VolunteerStreamFailed extends VolunteerEvent {
  final Object error;

  VolunteerStreamFailed(this.error);
}

class FilterVolunteer extends VolunteerEvent {
  final String? tim;
  final String? jenisKelamin;

  FilterVolunteer({this.tim, this.jenisKelamin});
}

class ToggleVolunteerStatus extends VolunteerEvent {
  final String id;

  final bool currentStatus;

  ToggleVolunteerStatus(this.id, this.currentStatus);
}

class GetVolunteerById extends VolunteerEvent {
  final String id;

  GetVolunteerById(this.id);
}

class ToggleVolunteerPIC extends VolunteerEvent {
  final String id;
  final bool currentStatus;
  final String tim;

  ToggleVolunteerPIC(this.id, this.currentStatus, this.tim);
}

/// Escalates a volunteer's warning level by one step (SP 1 → SP 2 → SP 3).
/// [currentLevel] must be the volunteer's SP level *before* escalation.
/// [reason] is required and is logged to the SP history collection.
class EscalateVolunteerSP extends VolunteerEvent {
  final String id;
  final int currentLevel;
  final String reason;
  final String volunteerName;

  EscalateVolunteerSP(
    this.id,
    this.currentLevel,
    this.reason,
    this.volunteerName,
  );
}

/// Undoes a volunteer's SP record back to 0. [currentLevel] must be the
/// volunteer's SP level *before* the undo. [reason] is required and is
/// logged to the SP history collection alongside the escalation entries.
class ResetVolunteerSP extends VolunteerEvent {
  final String id;
  final int currentLevel;
  final String reason;
  final String volunteerName;

  ResetVolunteerSP(this.id, this.currentLevel, this.reason, this.volunteerName);
}
