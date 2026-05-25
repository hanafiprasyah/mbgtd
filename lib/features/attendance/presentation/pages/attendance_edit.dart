import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditAttendancePage extends StatefulWidget {
  final String attendanceId;

  final Map<String, dynamic> data;
  const EditAttendancePage({
    super.key,
    required this.attendanceId,
    required this.data,
  });

  @override
  State<EditAttendancePage> createState() => _EditAttendancePageState();
}

class _EditAttendancePageState extends State<EditAttendancePage> {
  String attendanceType = "full";
  double multiplier = 1.0;
  final noteController = TextEditingController();
  @override
  void initState() {
    super.initState();

    attendanceType = widget.data['attendanceType'] ?? "full";

    multiplier = (widget.data['multiplier'] ?? 1.0).toDouble();

    noteController.text = widget.data['note'] ?? "";
  }

  void updateAttendance() async {
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(widget.attendanceId)
        .update({
          "attendanceType": attendanceType,
          "multiplier": multiplier,
          "note": noteController.text,
        });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: attendanceType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: "full", child: Text("Full Day")),
                DropdownMenuItem(value: "half", child: Text("Half Day")),
                DropdownMenuItem(value: "custom", child: Text("Custom")),
              ],

              onChanged: (value) {
                setState(() {
                  attendanceType = value!;
                  if (value == "full") multiplier = 1.0;
                  if (value == "half") multiplier = 0.5;
                });
              },
            ),

            const SizedBox(height: 16),

            if (attendanceType == "custom")
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Multiplier"),
                onChanged: (val) {
                  multiplier = double.tryParse(val) ?? 1.0;
                },
              ),

            const SizedBox(height: 16),

            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: "Note"),
            ),

            const SizedBox(height: 24),

            ElevatedButton(onPressed: updateAttendance, child: Text("Save")),
          ],
        ),
      ),
    );
  }
}
