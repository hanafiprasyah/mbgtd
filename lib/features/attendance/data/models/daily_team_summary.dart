class DailyTeamAttendanceSummary {
  final String date;
  final String tim;
  final int fullCount;
  final int halfCount;
  final int absentCount;
  final int baseSalary;

  DailyTeamAttendanceSummary({
    required this.date,
    required this.tim,
    required this.fullCount,
    required this.halfCount,
    required this.absentCount,
    required this.baseSalary,
  });
}
