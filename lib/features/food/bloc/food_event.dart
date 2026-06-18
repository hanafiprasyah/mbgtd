import 'dart:io';

import 'package:mbg_test/features/food/data/models/food_model.dart';

abstract class FoodEvent {}

class LoadFoods extends FoodEvent {}

class AddFood extends FoodEvent {
  final Food food;
  final File? photoFile; // file if exist
  AddFood(this.food, {this.photoFile});
}

class UpdateFood extends FoodEvent {
  final Food food;
  final File? newPhotoFile; // if photos changed
  UpdateFood(this.food, {this.newPhotoFile});
}

class DeleteFood extends FoodEvent {
  final String id;
  DeleteFood(this.id);
}
