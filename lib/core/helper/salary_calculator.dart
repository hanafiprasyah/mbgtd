const Map<String, int> salaryPerTim = {
  'ASLAP': 200000,
  'Chef': 180000,
  'Masak': 145000,
  'Persiapan': 125000,
  'Packing': 125000,
  'Pencucian': 125000,
  'Distribusi': 135000,
  'Satpam': 150000,
};

int calculateSalary(int totalScan, String tim) {
  final salary = salaryPerTim[tim] ?? 0;
  return totalScan * salary;
}

int getBaseSalary(String tim) {
  return salaryPerTim[tim] ?? 0;
}
