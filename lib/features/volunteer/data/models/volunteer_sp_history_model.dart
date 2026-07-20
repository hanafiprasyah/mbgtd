import 'package:cloud_firestore/cloud_firestore.dart';

/// What happened in this history entry.
enum SpAction { issued, undo }

extension SpActionX on SpAction {
  String get value => this == SpAction.issued ? 'issued' : 'undo';

  static SpAction fromValue(String? value) {
    return value == 'undo' ? SpAction.undo : SpAction.issued;
  }
}

/// A single audit-trail entry for a volunteer's SP (Surat Peringatan /
/// warning) record. Stored in the top-level `volunteer_sp_history`
/// collection, one document per issue or undo action, so the full timeline
/// (date, level, reason) can be reconstructed for a volunteer.
class VolunteerSpHistory {
  final String id;
  final String volunteerId;
  final String volunteerName;
  final SpAction action;
  final int previousLevel;
  final int newLevel;
  final String reason;
  final String? performedBy;
  final DateTime createdAt;

  VolunteerSpHistory({
    required this.id,
    required this.volunteerId,
    required this.volunteerName,
    required this.action,
    required this.previousLevel,
    required this.newLevel,
    required this.reason,
    this.performedBy,
    required this.createdAt,
  });

  factory VolunteerSpHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAtRaw = data['createdAt'];

    return VolunteerSpHistory(
      id: doc.id,
      volunteerId: data['volunteerId'] ?? '',
      volunteerName: data['volunteerName'] ?? '',
      action: SpActionX.fromValue(data['action']),
      previousLevel: data['previousLevel'] ?? 0,
      newLevel: data['newLevel'] ?? 0,
      reason: data['reason'] ?? '',
      performedBy: data['performedBy'],
      // A freshly-written serverTimestamp can briefly be null on the local
      // cache before the server round-trip resolves it, so fall back to
      // "now" rather than crash.
      createdAt: createdAtRaw is Timestamp
          ? createdAtRaw.toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'action': action.value,
      'previousLevel': previousLevel,
      'newLevel': newLevel,
      'reason': reason,
      'performedBy': performedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
