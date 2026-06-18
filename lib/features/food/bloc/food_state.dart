import 'package:mbg_test/features/food/data/models/food_model.dart';

enum FoodStatus { initial, loading, success, error }

class FoodState {
  final List<Food> foods;
  final FoodStatus status;
  final String? errorMessage;

  FoodState({
    this.foods = const [],
    this.status = FoodStatus.initial,
    this.errorMessage,
  });

  FoodState copyWith({
    List<Food>? foods,
    FoodStatus? status,
    String? errorMessage,
  }) {
    return FoodState(
      foods: foods ?? this.foods,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
