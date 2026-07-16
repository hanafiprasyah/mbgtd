abstract class VolunteerAccountEvent {}

class SubmitVolunteerAccount extends VolunteerAccountEvent {
  final String volunteerId;
  final String email;
  final String password;
  final String fullname;
  final String username;

  SubmitVolunteerAccount({
    required this.volunteerId,
    required this.email,
    required this.password,
    required this.fullname,
    required this.username,
  });
}
