class TeamPayrollRule {
  final String tim;
  final int baseSalary;
  final bool sharedPayroll;
  final bool isChefOrAslap;

  TeamPayrollRule({
    required this.tim,
    required this.baseSalary,
    required this.sharedPayroll,
    this.isChefOrAslap = false,
  });
}
