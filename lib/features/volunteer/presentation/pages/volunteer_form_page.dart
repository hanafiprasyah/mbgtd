import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/volunteer_bloc.dart';
import '../../bloc/volunteer_event.dart';
import '../../data/models/volunteer_model.dart';

class VolunteerFormPage extends StatefulWidget {
  const VolunteerFormPage({super.key});

  @override
  State<VolunteerFormPage> createState() => _VolunteerFormPageState();
}

class _VolunteerFormPageState extends State<VolunteerFormPage> {
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
    );

    final bloc = context.read<VolunteerBloc>();

    if (existing == null) {
      bloc.add(AddVolunteer(volunteer));
    } else {
      bloc.add(UpdateVolunteer(volunteer));
    }

    Navigator.pushReplacementNamed(
      context,
      '/volunteer-detail',
      arguments: volunteer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add Volunteer' : 'Edit Volunteer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),

            TextField(
              controller: alamatController,
              decoration: const InputDecoration(labelText: 'Address'),
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

            DropdownButton<String>(
              value: gender,
              items: [
                'Laki-laki',
                'Perempuan',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => gender = val!),
            ),

            const SizedBox(height: 10),

            DropdownButton<String>(
              value: tim,
              items: [
                'Persiapan',
                'Masak',
                'Distribusi',
                'Packing',
                'Pencucian',
                'Satpam',
                'ASLAP',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => tim = val!),
            ),

            ElevatedButton(onPressed: save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
