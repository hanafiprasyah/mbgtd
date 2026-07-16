import 'package:equatable/equatable.dart';
import 'package:mbg_test/features/users/data/models/user_model.dart';

abstract class VolunteerAccountState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VolunteerAccountInitial extends VolunteerAccountState {}

class VolunteerAccountSubmitting extends VolunteerAccountState {}

class VolunteerAccountSuccess extends VolunteerAccountState {
  final UserModel user;

  VolunteerAccountSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class VolunteerAccountError extends VolunteerAccountState {
  final String message;

  VolunteerAccountError(this.message);

  @override
  List<Object?> get props => [message];
}
