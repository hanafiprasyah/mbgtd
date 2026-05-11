import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/volunteer_bloc.dart';
import '../../bloc/volunteer_event.dart';
import '../../bloc/volunteer_state.dart';
import '../../data/models/volunteer_model.dart';

class VolunteerFormPage extends StatefulWidget {
  const VolunteerFormPage({super.key});

  @override
  State<VolunteerFormPage> createState() => _VolunteerFormPageState();
}

class _VolunteerFormPageState extends State<VolunteerFormPage> {
  final _formKey = GlobalKey<FormState>();

  final namaController = TextEditingController();
  final alamatController = TextEditingController();

  DateTime? selectedDate;
  Volunteer? existing;

  String gender = 'Laki-laki';
  String tim = 'Masak';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    existing = ModalRoute.of(context)?.settings.arguments as Volunteer?;

    if (existing != null && namaController.text.isEmpty) {
      namaController.text = existing!.namaLengkap;
      alamatController.text = existing!.alamat;
      gender = existing!.jenisKelamin;
      tim = existing!.tim;
      selectedDate = existing!.tanggalLahir;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal lahir wajib dipilih')),
      );
      return;
    }

    final volunteer = Volunteer(
      id: existing?.id ?? '',
      namaLengkap: namaController.text,
      tanggalLahir: selectedDate!,
      alamat: alamatController.text,
      jenisKelamin: gender,
      tim: tim,
      namaSearch: namaController.text.toLowerCase(),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add Volunteer' : 'Edit Volunteer'),
      ),
      body: BlocConsumer<VolunteerBloc, VolunteerState>(
        listener: (context, state) {
          if (state is VolunteerSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Berhasil menyimpan data')),
            );

            Navigator.pushReplacementNamed(
              context,
              '/volunteer-detail',
              arguments: state.volunteer,
            );
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
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: namaController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Nama wajib diisi'
                            : null,
                      ),

                      TextFormField(
                        controller: alamatController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Alamat wajib diisi'
                            : null,
                      ),

                      const SizedBox(height: 10),

                      ListTile(
                        title: Text(
                          selectedDate == null
                              ? 'Select Birth Date'
                              : DateFormat('dd MMM yyyy').format(selectedDate!),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: pickDate,
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        initialValue: gender,
                        items: ['Laki-laki', 'Perempuan']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => gender = val!),
                        decoration: const InputDecoration(labelText: 'Gender'),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        initialValue: tim,
                        items:
                            [
                                  'Persiapan',
                                  'Masak',
                                  'Distribusi',
                                  'Packing',
                                  'Pencucian',
                                  'Satpam',
                                  'ASLAP',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => tim = val!),
                        decoration: const InputDecoration(labelText: 'Tim'),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: isLoading ? null : save,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),

              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
