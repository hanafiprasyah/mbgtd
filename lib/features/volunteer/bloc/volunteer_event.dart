abstract class VolunteerEvent {}

class LoadVolunteer extends VolunteerEvent {}

class AddVolunteer extends VolunteerEvent {
  final dynamic volunteer;
  AddVolunteer(this.volunteer);
}

class UpdateVolunteer extends VolunteerEvent {
  final dynamic volunteer;
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
