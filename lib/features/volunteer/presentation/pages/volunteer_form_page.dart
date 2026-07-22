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

    final bloc = context.read<VolunteerBloc>();
    if (_existing == null) {
      bloc.add(AddVolunteer(volunteer));
    } else {
      bloc.add(UpdateVolunteer(volunteer));
    }
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
