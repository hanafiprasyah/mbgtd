import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/volunteer_model.dart';
import 'package:mbg_test/core/helper/design_system.dart';

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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Card(
          elevation: AppElevation.medium,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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

                const SizedBox(height: AppSpacing.md),

                Text("Address: ${volunteer.alamat}"),
                Text("Gender: ${volunteer.jenisKelamin}"),
                Text("Team: ${volunteer.tim}"),
                Text(
                  "Birth date: ${DateFormat('dd MMM yyyy').format(volunteer.tanggalLahir)}",
                ),

                const SizedBox(height: AppSpacing.lg),

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

                const SizedBox(height: AppSpacing.lg),

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
