class TeamPayrollResult {
  final String date;
  final String tim;
  final int fullCount;
  final int halfCount;
  final int absentCount;
  final int baseSalary;
  final double missingWorkload;
  final double totalBurden;
  final double sharePerFulltime;

  TeamPayrollResult({
    required this.date,
    required this.tim,
    required this.fullCount,
    required this.halfCount,
    required this.absentCount,
    required this.baseSalary,
    required this.missingWorkload,
    required this.totalBurden,
    required this.sharePerFulltime,
  });
}
