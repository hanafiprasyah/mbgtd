import 'package:equatable/equatable.dart';
import 'package:mbg_test/features/kitchen/data/models/kitchen_model.dart';

abstract class KitchenState extends Equatable {
  const KitchenState();

  @override
  List<Object?> get props => [];
}

class KitchenInitial extends KitchenState {}

class KitchenLoading extends KitchenState {}

class KitchenLoaded extends KitchenState {
  final List<KitchenModel> kitchens;
  const KitchenLoaded(this.kitchens);

  @override
  List<Object?> get props => [kitchens];
}

class KitchenDetailLoading extends KitchenState {}

class KitchenDetailLoaded extends KitchenState {
  final KitchenModel kitchen;
  const KitchenDetailLoaded(this.kitchen);

  @override
  List<Object?> get props => [kitchen];
}

class KitchenOperationInProgress extends KitchenState {}

class KitchenOperationSuccess extends KitchenState {
  final String message;
  const KitchenOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class KitchenError extends KitchenState {
  final String message;
  const KitchenError(this.message);

  @override
  List<Object?> get props => [message];
}
