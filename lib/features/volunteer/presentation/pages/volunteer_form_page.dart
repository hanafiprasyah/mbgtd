import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/volunteer_bloc.dart';
import '../../bloc/volunteer_event.dart';
import '../../bloc/volunteer_state.dart';
import '../../data/models/volunteer_model.dart';
import 'package:mbg_test/core/helper/design_system.dart';

class VolunteerFormPage extends StatefulWidget {
  const VolunteerFormPage({super.key});

  @override
  State<VolunteerFormPage> createState() => _VolunteerFormPageState();
}

class _VolunteerFormPageState extends State<VolunteerFormPage> {
  final _formKey = GlobalKey<FormState>();

  final namaController = TextEditingController();
  final alamatController = TextEditingController();
  final noRekController = TextEditingController();

  DateTime? selectedDate;
  Volunteer? existing;
  bool isActive = true;

  String gender = 'Laki-laki';
  String tim = 'Masak';
  String namaBank = 'BNI';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    existing = ModalRoute.of(context)?.settings.arguments as Volunteer?;
    if (existing != null) {
      isActive = existing!.isActive;
    }

    if (existing != null && namaController.text.isEmpty) {
      namaController.text = existing!.namaLengkap;
      alamatController.text = existing!.alamat;
      gender = existing!.jenisKelamin;
      tim = existing!.tim;
      selectedDate = existing!.tanggalLahir;
      noRekController.text = existing!.noRek ?? '';
      namaBank = (existing!.namaBank ?? 'BCA').toUpperCase().trim();
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? existing?.tanggalLahir ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void save() {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose birth date!')));
      return;
    }

    final volunteer = Volunteer(
      id: existing?.id ?? '',
      namaLengkap: namaController.text,
      tanggalLahir: selectedDate!,
      alamat: alamatController.text,
      jenisKelamin: gender,
      tim: tim,
      isActive: isActive,
      namaSearch: namaController.text.toLowerCase(),
      noRek: noRekController.text,
      namaBank: namaBank,
    );

    final bloc = context.read<VolunteerBloc>();

    if (existing == null) {
      bloc.add(AddVolunteer(volunteer));
    } else {
      bloc.add(UpdateVolunteer(volunteer));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        title: Text(existing == null ? 'Add Volunteer' : 'Edit Volunteer'),
      ),
      body: BlocConsumer<VolunteerBloc, VolunteerState>(
        listener: (context, state) {
          if (state is VolunteerSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Saved successfully')));

            // Return updated data to previous page (detail)
            Navigator.pop(context, state.volunteer);
          }

          if (state is VolunteerError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is VolunteerLoading;

          return Stack(
            children: [
              GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Personal Info',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: namaController,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Enter full name'
                                      : null,
                                ),

                                const SizedBox(height: AppSpacing.md),

                                TextFormField(
                                  controller: alamatController,
                                  decoration: const InputDecoration(
                                    labelText: 'Address',
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Enter address'
                                      : null,
                                ),

                                const SizedBox(height: AppSpacing.md),
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      [
                                        'Laki-laki',
                                        'Perempuan',
                                      ].contains(gender)
                                      ? gender
                                      : null,
                                  items: ['Laki-laki', 'Perempuan']
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => gender = val!),
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),

                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedDate == null
                                            ? 'Select Birth Date'
                                            : DateFormat(
                                                'dd MMM yyyy',
                                              ).format(selectedDate!),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to choose date',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.calendar_today),
                                  onTap: pickDate,
                                ),

                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'Work Info',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),

                                TextFormField(
                                  controller: noRekController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Account Number',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter account number';
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      return 'Account number must be numbers only';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: AppSpacing.md),

                                DropdownButtonFormField<String>(
                                  initialValue:
                                      [
                                        'BCA',
                                        'BRI',
                                        'BNI',
                                        'MANDIRI',
                                        'CIMB Niaga',
                                        'OCBC NISP',
                                        'MAYBANK',
                                      ].contains(namaBank)
                                      ? namaBank
                                      : null,
                                  items:
                                      [
                                            'BCA',
                                            'BRI',
                                            'BNI',
                                            'MANDIRI',
                                            'CIMB Niaga',
                                            'OCBC NISP',
                                            'MAYBANK',
                                          ]
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) =>
                                      setState(() => namaBank = val!),
                                  decoration: const InputDecoration(
                                    labelText: 'Bank Name',
                                  ),
                                ),

                                const SizedBox(height: AppSpacing.md),

                                DropdownButtonFormField<String>(
                                  initialValue:
                                      [
                                        'Chef',
                                        'ASLAP',
                                        'Persiapan',
                                        'Masak',
                                        'Distribusi',
                                        'Packing',
                                        'Pencucian',
                                        'Satpam',
                                      ].contains(tim)
                                      ? tim
                                      : null,
                                  items:
                                      [
                                            'Chef',
                                            'ASLAP',
                                            'Persiapan',
                                            'Masak',
                                            'Distribusi',
                                            'Packing',
                                            'Pencucian',
                                            'Satpam',
                                          ]
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) =>
                                      setState(() => tim = val!),
                                  decoration: const InputDecoration(
                                    labelText: 'Team',
                                  ),
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Status'),
                                    Switch(
                                      value: isActive,
                                      onChanged: (val) {
                                        setState(() {
                                          isActive = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),

                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : save,
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
