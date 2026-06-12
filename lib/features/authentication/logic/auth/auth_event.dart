abstract class AuthEvent {}

class AuthStarted extends AuthEvent {}

class AuthLoggedOut extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final bool isLoggedIn;

  AuthUserChanged(this.isLoggedIn);
}
