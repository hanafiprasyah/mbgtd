import 'package:rxdart/rxdart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/helper/firebase_crud_error.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repository;

  UserBloc(this.repository) : super(UserInitial()) {
    EventTransformer<T> debounce<T>(Duration duration) {
      return (events, mapper) =>
          events.distinct().debounceTime(duration).switchMap(mapper);
    }

    // Cancels the previous in-flight handler (and its underlying Firestore
    // listener) whenever a new event of the same type comes in. Without
    // this, LoadUser/FilterUser stack up concurrent `getUsers()` listeners
    // every time they're re-dispatched (refresh, after a mutation, etc.),
    // and each Firestore change then gets emitted once per open listener.
    EventTransformer<T> restartable<T>() {
      return (events, mapper) => events.switchMap(mapper);
    }

    on<LoadUser>((event, emit) async {
      emit(UserLoading());
      await emit.forEach<List<UserModel>>(
        repository.getUsers(),
        onData: (data) => UserLoaded(data),
      );
    }, transformer: restartable());

    on<AddUser>((event, emit) async {
      emit(UserLoading());
      try {
        await repository.addUser(event.user);
        emit(UserSuccess(event.user));
      } catch (e) {
        emit(UserError(mapFirebaseError(e)));
      }
    });

    on<UpdateUser>((event, emit) async {
      emit(UserLoading());
      try {
        await repository.updateUser(event.user);
        emit(UserSuccess(event.user));
      } catch (e) {
        emit(UserError(mapFirebaseError(e)));
      }
    });

    on<DeleteUser>((event, emit) async {
      emit(UserLoading());
      try {
        await repository.deleteUser(event.id);
        emit(UserSuccess(null));
      } catch (e) {
        emit(UserError(mapFirebaseError(e)));
      }
    });

    on<SearchUser>((event, emit) async {
      emit(UserLoading());

      final hasFilter = event.role != null && event.role!.isNotEmpty;
      final query = event.query.trim();

      // Route through the same repository call LoadUser uses when there's
      // nothing to actually search/filter by — but stay inside this
      // handler (and its switchMap transformer) so the listener is
      // properly cancelled the next time SearchUser fires, instead of
      // handing off to LoadUser's separate, unrelated subscription.
      final stream = query.isEmpty && !hasFilter
          ? repository.getUsers()
          : repository.searchUsers(query, role: event.role);

      await emit.forEach<List<UserModel>>(
        stream,
        onData: (data) => UserLoaded(data),
      );
    }, transformer: debounce(const Duration(milliseconds: 500)));

    on<FilterUser>((event, emit) async {
      emit(UserLoading());
      await emit.forEach<List<UserModel>>(
        repository.getUsers(role: event.role),
        onData: (data) => UserLoaded(data),
      );
    }, transformer: restartable());

    on<GetUserById>((event, emit) async {
      emit(UserLoading());
      try {
        final user = await repository.getUserById(event.id);
        emit(UserDetailLoaded(user));
      } catch (e) {
        emit(UserError(mapFirebaseError(e)));
      }
    });
  }
}
