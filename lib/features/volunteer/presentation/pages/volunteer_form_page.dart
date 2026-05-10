import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  String gender = 'Laki-laki';
  String tim = 'Masak';

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VolunteerBloc>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Volunteer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: namaController),
            TextField(controller: alamatController),

            DropdownButton<String>(
              value: gender,
              items: [
                'Laki-laki',
                'Perempuan',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => gender = val!),
            ),

            DropdownButton<String>(
              value: tim,
              items: [
                'Persiapan',
                'Masak',
                'Distribusi',
                'Packing',
                'Pencucian',
                'Satpam',
                'Aslap',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => tim = val!),
            ),

            ElevatedButton(
              onPressed: () {
                final volunteer = Volunteer(
                  id: '',
                  namaLengkap: namaController.text,
                  tanggalLahir: DateTime.now(),
                  alamat: alamatController.text,
                  jenisKelamin: gender,
                  tim: tim,
                );

                bloc.add(AddVolunteer(volunteer));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
