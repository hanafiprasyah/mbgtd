import 'package:equatable/equatable.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';

abstract class VolunteerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VolunteerInitial extends VolunteerState {}

class VolunteerLoading extends VolunteerState {}

class VolunteerLoaded extends VolunteerState {
  final List<Volunteer> volunteer;

  VolunteerLoaded(this.volunteer);

  @override
  List<Object?> get props => [volunteer];
}

class VolunteerSuccess extends VolunteerState {
  final Volunteer? volunteer;
  VolunteerSuccess(this.volunteer);

  @override
  List<Object?> get props => [volunteer];
}

class VolunteerError extends VolunteerState {
  final String message;
  VolunteerError(this.message);

  @override
  List<Object?> get props => [message];
}

class VolunteerDetailLoaded extends VolunteerState {
  final Volunteer volunteer;
  VolunteerDetailLoaded(this.volunteer);

  @override
  List<Object?> get props => [volunteer];
}
