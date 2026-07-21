import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/kitchen/data/models/kitchen_model.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_bloc.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_event.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_state.dart';

class KitchenFormScreen extends StatelessWidget {
  final KitchenModel? existing;
  const KitchenFormScreen({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KitchenBloc(),
      child: _KitchenFormView(existing: existing),
    );
  }
}

class _KitchenFormView extends StatefulWidget {
  final KitchenModel? existing;
  const _KitchenFormView({this.existing});

  @override
  State<_KitchenFormView> createState() => _KitchenFormViewState();
}

class _KitchenFormViewState extends State<_KitchenFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _ketuaController;
  late final TextEditingController _idKetuaController;
  late final TextEditingController _addressController;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _idController = TextEditingController(text: existing?.id ?? '');
    _nameController = TextEditingController(text: existing?.name ?? '');
    _ketuaController = TextEditingController(text: existing?.ketua ?? '');
    _idKetuaController = TextEditingController(text: existing?.idKetua ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ketuaController.dispose();
    _idKetuaController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final kitchen = KitchenModel(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      ketua: _ketuaController.text.trim(),
      idKetua: _idKetuaController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (_isEditing) {
      context.read<KitchenBloc>().add(UpdateKitchen(kitchen));
    } else {
      context.read<KitchenBloc>().add(AddKitchen(kitchen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Kitchen' : 'Add Kitchen'),
        centerTitle: true,
      ),
      body: BlocConsumer<KitchenBloc, KitchenState>(
        listener: (context, state) {
          if (state is KitchenError) {
            GlobalScaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 1),
              ),
            );
          }
          if (state is KitchenOperationSuccess) {
            GlobalScaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 1),
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          final isSubmitting = state is KitchenOperationInProgress;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _idController,
                      enabled: !_isEditing,
                      decoration: InputDecoration(
                        labelText: 'Doc ID',
                        hintText: 'e.g. kober, tanjung-durian',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Doc ID is required';
                        }
                        if (RegExp(r'[^a-zA-Z0-9_-]').hasMatch(value.trim())) {
                          return 'Only letters, numbers, "-" and "_" are allowed';
                        }
                        return null;
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'This ID becomes the kitchen\'s unique identifier '
                        '(kitchenId) and cannot be changed once created. '
                        'Use a simple format, e.g. "kober".',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Kitchen Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Kitchen name is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _ketuaController,
                      decoration: InputDecoration(
                        labelText: 'Head / SPPI',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Head/SPPI name is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _idKetuaController,
                      decoration: InputDecoration(
                        labelText: 'Head ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Head ID is required'
                          : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'Tip: Head ID is the Firebase Auth UID of the '
                        'kitchen head/SPPI. Don\'t have an account yet? '
                        'Contact the developer to register the head\'s '
                        'account before filling in this field.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Address is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isEditing ? 'Save Changes' : 'Add Kitchen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
