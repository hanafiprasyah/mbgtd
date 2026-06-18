import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/food/data/models/food_model.dart';
import 'package:mbg_test/features/food/data/repositories/food_repository.dart';
import 'food_event.dart';
import 'food_state.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final FoodRepository _repository;

  FoodBloc(this._repository) : super(FoodState()) {
    on<LoadFoods>(_onLoadFoods);
    on<AddFood>(_onAddFood);
    on<UpdateFood>(_onUpdateFood);
    on<DeleteFood>(_onDeleteFood);
  }

  Future<void> _onLoadFoods(LoadFoods event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    try {
      final foods = await _repository.getFoods();
      emit(state.copyWith(foods: foods, status: FoodStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: FoodStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onAddFood(AddFood event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    try {
      String? photoUrl;
      if (event.photoFile != null) {
        photoUrl = await _repository.uploadPhoto(event.photoFile!);
      }
      final foodToSave = Food(
        name: event.food.name,
        periode: event.food.periode,
        dibuatOleh: event.food.dibuatOleh,
        dimasakOleh: event.food.dimasakOleh,
        diketahuiOleh: event.food.diketahuiOleh,
        karbohidrat: event.food.karbohidrat,
        protein: event.food.protein,
        lemak: event.food.lemak,
        energi: event.food.energi,
        serat: event.food.serat,
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );
      await _repository.addFood(foodToSave);
      emit(state.copyWith(status: FoodStatus.success));
      add(LoadFoods()); // refresh list
    } catch (e) {
      emit(
        state.copyWith(status: FoodStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onUpdateFood(UpdateFood event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    try {
      String? photoUrl = event.food.photoUrl; // use old photo
      if (event.newPhotoFile != null) {
        photoUrl = await _repository.uploadPhoto(event.newPhotoFile!);
      }
      final updatedFood = Food(
        id: event.food.id,
        name: event.food.name,
        periode: event.food.periode,
        dibuatOleh: event.food.dibuatOleh,
        dimasakOleh: event.food.dimasakOleh,
        diketahuiOleh: event.food.diketahuiOleh,
        karbohidrat: event.food.karbohidrat,
        protein: event.food.protein,
        lemak: event.food.lemak,
        energi: event.food.energi,
        serat: event.food.serat,
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );
      await _repository.updateFood(updatedFood);
      emit(state.copyWith(status: FoodStatus.success));
      add(LoadFoods());
    } catch (e) {
      emit(
        state.copyWith(status: FoodStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onDeleteFood(DeleteFood event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    try {
      final foodToDelete = state.foods.firstWhere(
        (f) => f.id == event.id,
        orElse: () => throw Exception('Food not found'),
      );

      // delete image if exist
      if (foodToDelete.photoUrl != null && foodToDelete.photoUrl!.isNotEmpty) {
        await _repository.deletePhoto(foodToDelete.photoUrl!);
      }

      // delete doc from 'foods' collection
      await _repository.deleteFood(event.id);

      emit(state.copyWith(status: FoodStatus.success));
      add(LoadFoods());
    } catch (e) {
      emit(
        state.copyWith(status: FoodStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
