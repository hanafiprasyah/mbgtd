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
