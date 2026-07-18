import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/food/bloc/food_bloc.dart';
import 'package:mbg_test/features/food/bloc/food_event.dart';
import 'package:mbg_test/features/food/bloc/food_state.dart';
import 'package:mbg_test/features/food/data/models/food_model.dart';
import 'package:mbg_test/features/users/data/models/user_model.dart';
import 'package:mbg_test/features/users/data/repositories/user_repository.dart';

class FoodFormScreen extends StatefulWidget {
  final Food? food;

  const FoodFormScreen({super.key, this.food});

  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _periodeCtrl;
  String? _dibuatOleh;
  String? _dimasakOleh;
  String? _diketahuiOleh;
  late TextEditingController _karboCtrl;
  final _userRepository = UserRepository();
  late TextEditingController _proteinCtrl;
  late TextEditingController _lemakCtrl;
  late TextEditingController _energiCtrl;
  late TextEditingController _seratCtrl;

  File? _selectedImage;
  String? _existingPhotoUrl;
  bool _isEditing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.food != null;
    final food = widget.food;
    _nameCtrl = TextEditingController(text: food?.name ?? '');
    _periodeCtrl = TextEditingController(text: food?.periode ?? '');
    _dibuatOleh = (food?.dibuatOleh.isNotEmpty ?? false)
        ? food!.dibuatOleh
        : null;
    _dimasakOleh = (food?.dimasakOleh.isNotEmpty ?? false)
        ? food!.dimasakOleh
        : null;
    _diketahuiOleh = (food?.diketahuiOleh.isNotEmpty ?? false)
        ? food!.diketahuiOleh
        : null;
    _karboCtrl = TextEditingController(
      text: food?.karbohidrat.toString() ?? '',
    );
    _proteinCtrl = TextEditingController(text: food?.protein.toString() ?? '');
    _lemakCtrl = TextEditingController(text: food?.lemak.toString() ?? '');
    _energiCtrl = TextEditingController(text: food?.energi.toString() ?? '');
    _seratCtrl = TextEditingController(text: food?.serat.toString() ?? '');
    _existingPhotoUrl = food?.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _periodeCtrl.dispose();
    _karboCtrl.dispose();
    _proteinCtrl.dispose();
    _lemakCtrl.dispose();
    _energiCtrl.dispose();
    _seratCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final foodData = Food(
      id: widget.food?.id,
      name: _nameCtrl.text.trim(),
      periode: _periodeCtrl.text.trim(),
      dibuatOleh: _dibuatOleh ?? '',
      dimasakOleh: _dimasakOleh ?? '',
      diketahuiOleh: _diketahuiOleh ?? '',
      karbohidrat: _parseNumeric(_karboCtrl.text),
      protein: _parseNumeric(_proteinCtrl.text),
      lemak: _parseNumeric(_lemakCtrl.text),
      energi: _parseNumeric(_energiCtrl.text),
      serat: _parseNumeric(_seratCtrl.text),
      photoUrl: _existingPhotoUrl,
    );

    final bloc = context.read<FoodBloc>();

    setState(() => _isSubmitting = true);

    if (_isEditing) {
      bloc.add(UpdateFood(foodData, newPhotoFile: _selectedImage));
    } else {
      bloc.add(AddFood(foodData, photoFile: _selectedImage));
    }

    // Wait specifically for the outcome of THIS submit (success or error).
    // bloc.add() only enqueues the event, the actual emit() calls happen
    // asynchronously afterwards, so subscribing to the stream here is safe
    // and will not miss the relevant state. firstWhere() resolves on the
    // very next match and then stops listening, so the follow-up
    // LoadFoods() refresh (which also emits a "success" state) is ignored
    // and can't trigger this method a second time.
    final result = await bloc.stream.firstWhere(
      (s) => s.status == FoodStatus.success || s.status == FoodStatus.error,
    );

    if (!mounted) return;

    if (result.status == FoodStatus.success) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSubmitting = false);
    GlobalScaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(result.errorMessage ?? 'Failed to save menu.'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Parses a numeric field, accepting both "," and "." as decimal separator
  // (matches the sanitization already done in _numericValidator).
  double _parseNumeric(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    final sanitized = trimmed.replaceAll(',', '.');
    return double.tryParse(sanitized) ?? 0;
  }

  // Validator for required text fields
  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _numericValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // field optional
    }

    final trimmed = value.trim();

    try {
      final number = NumberFormat().parse(trimmed);
      if (number < 0) {
        return '$fieldName cannot be negative';
      }
      return null;
    } catch (_) {
      final sanitized = trimmed.replaceAll(',', '.');
      final number = double.tryParse(sanitized);
      if (number == null) {
        return 'Please enter a valid number for $fieldName (use . or , as decimal separator)';
      }
      if (number < 0) {
        return '$fieldName cannot be negative';
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Menu' : 'Add Menu'),
          backgroundColor: colorScheme.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: BackButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Section: Menu ===
                  _buildSectionHeader(
                    'Menu Information',
                    Icons.restaurant_menu,
                  ),
                  const SizedBox(height: 16),

                  // Photo upload
                  _buildPhotoUpload(),
                  const SizedBox(height: 20),

                  // Name - Required
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Menu Name',
                      hintText: 'e.g., Nasi Goreng Special',
                      prefixIcon: const Icon(Icons.food_bank),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                    validator: (v) => _requiredValidator(v, 'Menu name'),
                  ),
                  const SizedBox(height: 16),

                  // Period - Required with hint below
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _periodeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Period',
                          hintText: 'e.g., Period 2 - 28 May 2025',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        validator: (v) => _requiredValidator(v, 'Period'),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Example: Period 2 - 28 May 2025, follow the example format carefully.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Created by (Nutritionist)
                  _buildUserDropdown(
                    label: 'Created by',
                    hint: 'Select Nutritionist',
                    icon: Icons.person_outline,
                    role: 'nutritionist',
                    value: _dibuatOleh,
                    onChanged: (v) => setState(() => _dibuatOleh = v),
                  ),
                  const SizedBox(height: 16),

                  // Cooked by (Chef)
                  _buildUserDropdown(
                    label: 'Cooked by',
                    hint: 'Select Chef',
                    icon: Icons.kitchen,
                    role: 'chef',
                    value: _dimasakOleh,
                    onChanged: (v) => setState(() => _dimasakOleh = v),
                  ),
                  const SizedBox(height: 16),

                  // Evaluated by (SPPI)
                  _buildUserDropdown(
                    label: 'Evaluated by',
                    hint: 'Select SPPI',
                    icon: Icons.rate_review,
                    role: 'sppi',
                    value: _diketahuiOleh,
                    onChanged: (v) => setState(() => _diketahuiOleh = v),
                  ),
                  const SizedBox(height: 32),

                  // === Section: AKG ===
                  _buildSectionHeader(
                    'Nutritional Values (AKG)',
                    Icons.analytics,
                  ),
                  const SizedBox(height: 16),

                  // Explanation
                  Text(
                    'Enter the nutritional content in grams (g) per serving. (Optional)',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid of 5 fields with validation
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3.4,
                    children: [
                      _buildAKGField('Carbohydrate', _karboCtrl),
                      _buildAKGField('Protein', _proteinCtrl),
                      _buildAKGField('Fat', _lemakCtrl),
                      _buildAKGField('Energy', _energiCtrl, suffix: 'kcal'),
                      _buildAKGField('Fiber', _seratCtrl),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Save button
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _save,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSubmitting
                          ? 'Saving...'
                          : (_isEditing ? 'Update Menu' : 'Save Menu'),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUpload() {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                )
              : _existingPhotoUrl != null
              ? DecorationImage(
                  image: NetworkImage(_existingPhotoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: (_selectedImage == null && _existingPhotoUrl == null)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 56,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload photo',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG, WEBP supported',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUserDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String role,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<UserModel>>(
      stream: _userRepository.getUsers(role: role),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Surface the real cause (e.g. Firestore permission-denied)
          // instead of leaving the dropdown silently unresponsive.
          debugPrint('getUsers(role: $role) error: ${snapshot.error}');
        }

        final names = <String>{
          ...?snapshot.data?.map((u) => u.fullname),
          if (value != null) value,
        }.toList();

        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            names.isEmpty;

        return DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: isLoading
                ? 'Loading...'
                : (names.isEmpty ? 'No $role found' : hint),
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          items: names
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: names.isEmpty ? null : onChanged,
          validator: (v) => _requiredValidator(v, 'This field'),
        );
      },
    );
  }

  Widget _buildAKGField(
    String label,
    TextEditingController ctrl, {
    String suffix = 'g',
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      validator: (v) => _numericValidator(v, label),
    );
  }
}
