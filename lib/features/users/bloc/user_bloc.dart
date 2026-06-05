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

    on<LoadUser>((event, emit) async {
      emit(UserLoading());
      await emit.forEach<List<UserModel>>(
        repository.getUsers(),
        onData: (data) => UserLoaded(data),
      );
    });

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
      final hasFilter = event.role != null && event.role!.isNotEmpty;
      if (event.query.trim().isEmpty && !hasFilter) {
        add(LoadUser());
        return;
      }

      emit(UserLoading());
      await emit.forEach<List<UserModel>>(
        repository.searchUsers(event.query, role: event.role),
        onData: (data) => UserLoaded(data),
      );
    }, transformer: debounce(const Duration(milliseconds: 500)));

    on<FilterUser>((event, emit) async {
      emit(UserLoading());
      await emit.forEach<List<UserModel>>(
        repository.getUsers(role: event.role),
        onData: (data) => UserLoaded(data),
      );
    });

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
