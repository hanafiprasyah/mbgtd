import 'package:equatable/equatable.dart';
import '../data/models/user_model.dart';

abstract class UserState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<UserModel> users;

  UserLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UserSuccess extends UserState {
  final UserModel? user;

  UserSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;

  UserError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserDetailLoaded extends UserState {
  final UserModel user;

  UserDetailLoaded(this.user);

  @override
  List<Object?> get props => [user];
}
