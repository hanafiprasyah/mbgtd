import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  String volunteerName = "Volunteer";
  String dateFormatted = "";
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    attendanceType = widget.data['attendanceType'] ?? "full";
    multiplier = (widget.data['multiplier'] ?? 1.0).toDouble();
    noteController.text = widget.data['note'] ?? "";
    volunteerName = widget.data['nama'] ?? "Volunteer";
    final rawDate = widget.data['date'];
    if (rawDate != null && rawDate.toString().isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(rawDate).toLocal();
        dateFormatted = DateFormat('dd MMM yyyy').format(parsedDate);
      } catch (e) {
        dateFormatted = rawDate;
      }
    } else {
      dateFormatted = "";
    }
  }

  void updateAttendance() async {
    await FirebaseFirestore.instance
        .collection('attendances')
        .doc(widget.attendanceId)
        .update({
          "attendanceType": attendanceType,
          "multiplier": multiplier,
          "note": noteController.text,
        });

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> deleteAttendance() async {
    await FirebaseFirestore.instance
        .collection('attendances')
        .doc(widget.attendanceId)
        .delete();

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _DeleteAttendanceDialog(
          volunteerName: volunteerName,
          onConfirmed: deleteAttendance,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Edit Attendance", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              "$volunteerName • $dateFormatted",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.primaryColor.withAlpha(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Attendance Settings",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Adjust type and multiplier easily",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Type Selector
              Text("Attendance Type", style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: attendanceType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: "full", child: Text("Full Day")),
                      DropdownMenuItem(value: "half", child: Text("Half Day")),
                      DropdownMenuItem(value: "absent", child: Text("Absent")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        attendanceType = value!;
                        if (value == "full") multiplier = 1.0;
                        if (value == "half") multiplier = 0.5;
                        if (value == "absent") multiplier = 0;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Multiplier Display
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.primaryColor.withAlpha(13),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Multiplier", style: TextStyle(fontSize: 13)),
                    Text(
                      multiplier.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Note Field
              Text("Note", style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),

              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Add optional note...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: updateAttendance,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Save Changes"),
                ),
              ),

              const SizedBox(height: 12),

              // Delete Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showDeleteConfirmationDialog,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    "Delete Attendance",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAttendanceDialog extends StatefulWidget {
  final String volunteerName;
  final VoidCallback onConfirmed;

  const _DeleteAttendanceDialog({
    required this.volunteerName,
    required this.onConfirmed,
  });

  @override
  State<_DeleteAttendanceDialog> createState() =>
      _DeleteAttendanceDialogState();
}

class _DeleteAttendanceDialogState extends State<_DeleteAttendanceDialog> {
  final _confirmController = TextEditingController();
  bool _isMatch = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_onConfirmTextChanged);
  }

  void _onConfirmTextChanged() {
    final matched =
        _confirmController.text.trim() == widget.volunteerName.trim();
    if (matched != _isMatch) {
      setState(() => _isMatch = matched);
    }
  }

  @override
  void dispose() {
    _confirmController.removeListener(_onConfirmTextChanged);
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text("Delete Attendance"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "This action cannot be undone. Please type the volunteer's full name below to confirm deletion:",
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.volunteerName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Type full name here",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isMatch
              ? () {
                  Navigator.pop(context);
                  widget.onConfirmed();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.red.withAlpha(60),
            foregroundColor: Colors.white,
          ),
          child: const Text("Delete"),
        ),
      ],
    );
  }
}
