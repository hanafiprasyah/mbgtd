import 'package:equatable/equatable.dart';
import 'package:mbg_test/features/kitchen/data/models/kitchen_model.dart';

abstract class KitchenEvent extends Equatable {
  const KitchenEvent();

  @override
  List<Object?> get props => [];
}

class LoadKitchens extends KitchenEvent {
  const LoadKitchens();
}

class LoadKitchenDetail extends KitchenEvent {
  final String id;
  const LoadKitchenDetail(this.id);

  @override
  List<Object?> get props => [id];
}

class AddKitchen extends KitchenEvent {
  final KitchenModel kitchen;
  const AddKitchen(this.kitchen);

  @override
  List<Object?> get props => [kitchen];
}

class UpdateKitchen extends KitchenEvent {
  final KitchenModel kitchen;
  const UpdateKitchen(this.kitchen);

  @override
  List<Object?> get props => [kitchen];
}

class DeleteKitchen extends KitchenEvent {
  final String id;
  const DeleteKitchen(this.id);

  @override
  List<Object?> get props => [id];
}
