import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_state.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';
import 'package:mbg_test/core/helper/design_system.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kGenders = ['Laki-laki', 'Perempuan'];
const _kBanks = [
  'BCA',
  'BRI',
  'BNI',
  'MANDIRI',
  'CIMB Niaga',
  'OCBC NISP',
  'MAYBANK',
];
const _kTeams = [
  'Chef',
  'ASLAP',
  'Persiapan',
  'Masak',
  'Distribusi',
  'Packing',
  'Pencucian',
  'Satpam',
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class VolunteerFormPage extends StatefulWidget {
  const VolunteerFormPage({super.key});

  @override
  State<VolunteerFormPage> createState() => _VolunteerFormPageState();
}

class _VolunteerFormPageState extends State<VolunteerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noRekController = TextEditingController();

  Volunteer? _existing;
  DateTime? _selectedDate;
  bool _isActive = true;
  String _gender = _kGenders.first;
  String _tim = 'Masak';
  String _namaBank = 'BNI';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _existing = ModalRoute.of(context)?.settings.arguments as Volunteer?;

    if (_existing != null && _namaController.text.isEmpty) {
      _namaController.text = _existing!.namaLengkap;
      _alamatController.text = _existing!.alamat;
      _noRekController.text = _existing!.noRek ?? '';
      _selectedDate = _existing!.tanggalLahir;
      _isActive = _existing!.isActive;
      _gender = _existing!.jenisKelamin;
      _tim = _existing!.tim;
      _namaBank = (_kBanks.contains(_existing!.namaBank?.toUpperCase().trim()))
          ? _existing!.namaBank!.toUpperCase().trim()
          : _kBanks.first;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _noRekController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      GlobalScaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Please select a birth date.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final volunteer = Volunteer(
      id: _existing?.id ?? '',
      namaLengkap: _namaController.text.trim(),
      tanggalLahir: _selectedDate!,
      alamat: _alamatController.text.trim(),
      jenisKelamin: _gender,
      tim: _tim,
      isActive: _isActive,
      namaSearch: _namaController.text.trim().toLowerCase(),
      noRek: _noRekController.text.trim(),
      namaBank: _namaBank,
    );

    if (_existing == null) {
      // Add flow: no confirmation dialog, save immediately.
      context.read<VolunteerBloc>().add(AddVolunteer(volunteer));
    } else {
      // Edit flow: require the user to review changes before saving.
      _confirmAndUpdate(volunteer);
    }
  }

  Future<void> _confirmAndUpdate(Volunteer updated) async {
    final changes = _buildFieldChanges(_existing!, updated);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _EditConfirmationDialog(changes: changes),
    );

    if (confirmed != true || !mounted) return;

    context.read<VolunteerBloc>().add(UpdateVolunteer(updated));
  }

  List<_FieldChange> _buildFieldChanges(Volunteer old, Volunteer updated) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return [
      _FieldChange(
        label: 'Full Name',
        oldValue: old.namaLengkap,
        newValue: updated.namaLengkap,
      ),
      _FieldChange(
        label: 'Address',
        oldValue: old.alamat,
        newValue: updated.alamat,
      ),
      _FieldChange(
        label: 'Gender',
        oldValue: old.jenisKelamin,
        newValue: updated.jenisKelamin,
      ),
      _FieldChange(
        label: 'Birth Date',
        oldValue: dateFormat.format(old.tanggalLahir),
        newValue: dateFormat.format(updated.tanggalLahir),
      ),
      _FieldChange(label: 'Team', oldValue: old.tim, newValue: updated.tim),
      _FieldChange(
        label: 'Account Number',
        oldValue: old.noRek ?? '',
        newValue: updated.noRek ?? '',
      ),
      _FieldChange(
        label: 'Bank Name',
        oldValue: old.namaBank ?? '',
        newValue: updated.namaBank ?? '',
      ),
      _FieldChange(
        label: 'Status',
        oldValue: old.isActive ? 'Active' : 'Inactive',
        newValue: updated.isActive ? 'Active' : 'Inactive',
      ),
    ];
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VolunteerBloc, VolunteerState>(
      listener: _handleState,
      builder: (context, state) {
        final isLoading = state is VolunteerLoading;

        return PopScope(
          // Block system back gesture / button while saving
          canPop: !isLoading,
          child: Scaffold(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            appBar: _buildAppBar(isLoading),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionCard(
                            icon: Icons.person_outline_rounded,
                            title: 'Personal Info',
                            children: [
                              _buildTextField(
                                controller: _namaController,
                                label: 'Full Name',
                                icon: Icons.badge_outlined,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter full name'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildTextField(
                                controller: _alamatController,
                                label: 'Address',
                                icon: Icons.home_outlined,
                                maxLines: 2,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter address'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildDropdown(
                                label: 'Gender',
                                icon: Icons.wc_outlined,
                                value: _gender,
                                items: _kGenders,
                                onChanged: (v) => setState(() => _gender = v!),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _DatePickerField(
                                selectedDate: _selectedDate,
                                onTap: _pickDate,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SectionCard(
                            icon: Icons.work_outline_rounded,
                            title: 'Work Info',
                            children: [
                              _buildDropdown(
                                label: 'Team',
                                icon: Icons.groups_outlined,
                                value: _kTeams.contains(_tim) ? _tim : null,
                                items: _kTeams,
                                onChanged: (v) => setState(() => _tim = v!),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildTextField(
                                controller: _noRekController,
                                label: 'Account Number',
                                icon: Icons.credit_card_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter account number';
                                  }
                                  if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                                    return 'Account number must contain digits only';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildDropdown(
                                label: 'Bank Name',
                                icon: Icons.account_balance_outlined,
                                value: _kBanks.contains(_namaBank)
                                    ? _namaBank
                                    : null,
                                items: _kBanks,
                                onChanged: (v) =>
                                    setState(() => _namaBank = v!),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _StatusToggle(
                                value: _isActive,
                                enabled: _existing != null,
                                onChanged: (v) => setState(() => _isActive = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _SaveButton(isLoading: isLoading, onPressed: _save),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Helper builders ────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      // Disable back button while saving
      automaticallyImplyLeading: !isLoading,
      title: Text(_existing == null ? 'Add Volunteer' : 'Edit Volunteer'),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      autovalidateMode: AutovalidateMode.always,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  // ── BLoC listener ──────────────────────────────────────────────────────────

  void _handleState(BuildContext context, VolunteerState state) {
    if (state is VolunteerSuccess) {
      GlobalScaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Saved successfully.'),
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.pop(context, state.volunteer);
    } else if (state is VolunteerError) {
      GlobalScaffoldMessenger.showSnackBar(
        SnackBar(content: Text(state.message), duration: Duration(seconds: 1)),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(
              height: 0,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.selectedDate, required this.onTap});

  final DateTime? selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDate = selectedDate != null;
    final label = hasDate
        ? DateFormat('dd MMM yyyy').format(selectedDate!)
        : 'Select birth date';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birth Date',
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: hasDate ? null : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? Colors.blueAccent : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.toggle_on_outlined, size: 20, color: effectiveColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Active Status',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: enabled ? null : Colors.grey,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: Colors.blueAccent,
          ),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              value ? 'Active' : 'Inactive',
              key: ValueKey(value),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled
                    ? (value ? Colors.blueAccent : Colors.grey)
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit confirmation
// ---------------------------------------------------------------------------

/// Represents a single form field's old and new value, used to render the
/// edit confirmation dialog. Only relevant for the edit flow — the add flow
/// has no "old" value to compare against.
class _FieldChange {
  const _FieldChange({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });

  final String label;
  final String oldValue;
  final String newValue;

  bool get isChanged => oldValue.trim() != newValue.trim();
}

/// Confirmation dialog shown before saving an edited volunteer. Lists every
/// field that will be saved; fields the user actually changed also show
/// their previous value (struck through) as a reference.
class _EditConfirmationDialog extends StatelessWidget {
  const _EditConfirmationDialog({required this.changes});

  final List<_FieldChange> changes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final changedCount = changes.where((c) => c.isChanged).length;

    return AlertDialog(
      title: const Text('Confirm Changes'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                changedCount > 0
                    ? 'Please review the data below before saving. '
                          '$changedCount field${changedCount > 1 ? 's' : ''} '
                          'changed.'
                    : 'No fields were changed. Save anyway?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final change in changes) ...[
                _FieldChangeTile(change: change),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Renders a single field row inside the edit confirmation dialog: label,
/// the new value that will be saved, and — only if the value actually
/// changed — the previous value shown struck through above it.
class _FieldChangeTile extends StatelessWidget {
  const _FieldChangeTile({required this.change});

  final _FieldChange change;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: change.isChanged
            ? colorScheme.primaryContainer.withValues(alpha: 0.25)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
        border: change.isChanged
            ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                change.label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              if (change.isChanged) ...[
                const SizedBox(width: 6),
                Icon(Icons.edit_rounded, size: 12, color: colorScheme.primary),
              ],
            ],
          ),
          const SizedBox(height: 2),
          if (change.isChanged)
            Text(
              change.oldValue.trim().isEmpty ? '(empty)' : change.oldValue,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            change.newValue.trim().isEmpty ? '(empty)' : change.newValue,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: change.isChanged
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.blueAccent.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
      ),
    );
  }
}
