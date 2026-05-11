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
  SearchVolunteer(this.query);
}

class FilterVolunteer extends VolunteerEvent {
  final String? tim;
  final String? jenisKelamin;

  FilterVolunteer({this.tim, this.jenisKelamin});
}
