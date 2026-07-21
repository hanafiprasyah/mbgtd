import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_event.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_state.dart';
import 'package:mbg_test/features/kitchen/data/models/kitchen_model.dart';
import 'package:mbg_test/features/kitchen/data/repositories/kitchen_repository.dart';

class KitchenBloc extends Bloc<KitchenEvent, KitchenState> {
  final KitchenRepository _repository;

  KitchenBloc({KitchenRepository? repository})
    : _repository = repository ?? KitchenRepository(),
      super(KitchenInitial()) {
    on<LoadKitchens>(_onLoadKitchens);
    on<LoadKitchenDetail>(_onLoadKitchenDetail);
    on<AddKitchen>(_onAddKitchen);
    on<UpdateKitchen>(_onUpdateKitchen);
    on<DeleteKitchen>(_onDeleteKitchen);
  }

  Future<void> _onLoadKitchens(
    LoadKitchens event,
    Emitter<KitchenState> emit,
  ) async {
    emit(KitchenLoading());
    await emit.forEach<List<KitchenModel>>(
      _repository.getKitchens(),
      onData: (kitchens) => KitchenLoaded(kitchens),
      onError: (error, stackTrace) => KitchenError(error.toString()),
    );
  }

  Future<void> _onLoadKitchenDetail(
    LoadKitchenDetail event,
    Emitter<KitchenState> emit,
  ) async {
    emit(KitchenDetailLoading());
    await emit.forEach<KitchenModel?>(
      _repository.streamKitchenById(event.id),
      onData: (kitchen) => kitchen == null
          ? const KitchenError('Kitchen not found.')
          : KitchenDetailLoaded(kitchen),
      onError: (error, stackTrace) => KitchenError(error.toString()),
    );
  }

  Future<void> _onAddKitchen(
    AddKitchen event,
    Emitter<KitchenState> emit,
  ) async {
    emit(KitchenOperationInProgress());
    try {
      await _repository.addKitchen(event.kitchen);
      emit(const KitchenOperationSuccess('Kitchen added successfully.'));
    } catch (e) {
      emit(KitchenError(e.toString()));
    }
  }

  Future<void> _onUpdateKitchen(
    UpdateKitchen event,
    Emitter<KitchenState> emit,
  ) async {
    emit(KitchenOperationInProgress());
    try {
      await _repository.updateKitchen(event.kitchen);
      emit(const KitchenOperationSuccess('Kitchen updated successfully.'));
    } catch (e) {
      emit(KitchenError(e.toString()));
    }
  }

  Future<void> _onDeleteKitchen(
    DeleteKitchen event,
    Emitter<KitchenState> emit,
  ) async {
    emit(KitchenOperationInProgress());
    try {
      await _repository.deleteKitchen(event.id);
      emit(const KitchenOperationSuccess('Kitchen deleted successfully.'));
    } catch (e) {
      emit(KitchenError(e.toString()));
    }
  }
}
