// Salary Calculator Helper

class TeamPayrollRule {
  final String tim;
  final int baseSalary;
  final bool sharedPayroll; // true: apply shared-burden logic
  final bool
  isChefOrAslap; // special handling (chef distribution or aslap own salary)

  const TeamPayrollRule({
    required this.tim,
    required this.baseSalary,
    this.sharedPayroll = true,
    this.isChefOrAslap = false,
  });
}

const Map<String, TeamPayrollRule> payrollRules = {
  'Persiapan': TeamPayrollRule(tim: 'Persiapan', baseSalary: 125000),
  'Masak': TeamPayrollRule(tim: 'Masak', baseSalary: 145000),
  'Packing': TeamPayrollRule(tim: 'Packing', baseSalary: 125000),
  'Pencucian': TeamPayrollRule(tim: 'Pencucian', baseSalary: 125000),
  'Distribusi': TeamPayrollRule(tim: 'Distribusi', baseSalary: 135000),
  'Satpam': TeamPayrollRule(tim: 'Satpam', baseSalary: 150000),
  'Chef': TeamPayrollRule(
    tim: 'Chef',
    baseSalary: 180000,
    sharedPayroll: false,
    isChefOrAslap: true,
  ),
  'ASLAP': TeamPayrollRule(
    tim: 'ASLAP',
    baseSalary: 200000,
    sharedPayroll: false,
    isChefOrAslap: true,
  ),
};

// Backwards-compatible helpers
int getBaseSalary(String tim) {
  final rule = payrollRules[tim];
  return rule?.baseSalary ?? 0;
}

int getHalfSalary(String tim) {
  final baseSalary = getBaseSalary(tim);
  return (baseSalary / 2).round();
}

// Shared-burden helpers
double calculateMissingWorkload(int halfCount, int absentCount) {
  return halfCount * 0.5 + absentCount.toDouble();
}

double calculateTotalBurden(int baseSalary, double missingWorkload) {
  return missingWorkload * baseSalary;
}

double calculateSharePerFulltime(int fullCount, double totalBurden) {
  if (fullCount <= 0) return 0.0;
  return totalBurden / fullCount;
}

double calculateMemberPay({
  required String attendanceType,
  required double multiplier,
  required int baseSalary,
  required double sharePerFulltime,
  required bool sharedPayroll,
}) {
  if (!sharedPayroll) {
    // For chef/aslap: pay only multiplier * baseSalary (no shared burden)
    return multiplier * baseSalary;
  }

  if (attendanceType == 'full') return baseSalary + sharePerFulltime;
  if (attendanceType == 'half') return multiplier * baseSalary;
  return 0.0; // absent
}

// Optional: helper to check if a team uses shared payroll
bool teamUsesSharedPayroll(String tim) {
  final rule = payrollRules[tim];
  return rule?.sharedPayroll ?? true;
}
