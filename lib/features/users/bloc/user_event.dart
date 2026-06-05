import '../data/models/user_model.dart';

abstract class UserEvent {}

class LoadUser extends UserEvent {}

class AddUser extends UserEvent {
  final UserModel user;

  AddUser(this.user);
}

class UpdateUser extends UserEvent {
  final UserModel user;

  UpdateUser(this.user);
}

class DeleteUser extends UserEvent {
  final String id;

  DeleteUser(this.id);
}

class SearchUser extends UserEvent {
  final String query;
  final String? role;

  SearchUser(this.query, this.role);
}

class FilterUser extends UserEvent {
  final String? role;

  FilterUser(this.role);
}

class GetUserById extends UserEvent {
  final String id;

  GetUserById(this.id);
}
