import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/volunteer_model.dart';

class VolunteerDetailPage extends StatelessWidget {
  const VolunteerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! Volunteer) {
      return const Scaffold(
        body: Center(child: Text('No volunteer data found')),
      );
    }

    final volunteer = args;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Volunteer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  volunteer.namaLengkap,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text("Alamat: ${volunteer.alamat}"),
                Text("Jenis Kelamin: ${volunteer.jenisKelamin}"),
                Text("Tim: ${volunteer.tim}"),
                Text(
                  "Tanggal Lahir: ${DateFormat('dd MMM yyyy').format(volunteer.tanggalLahir)}",
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/volunteer-add',
                      arguments: volunteer,
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/qr-generator',
                      arguments: volunteer,
                    );
                  },
                  child: Text('Generate QR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
