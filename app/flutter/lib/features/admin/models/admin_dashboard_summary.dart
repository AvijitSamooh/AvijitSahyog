class AdminDashboardMetric {
  const AdminDashboardMetric({
    required this.total,
    required this.active,
    required this.inactive,
  });
  final int total;
  final int active;
  final int inactive;

  factory AdminDashboardMetric.fromJson(Map<String, dynamic> json) =>
      AdminDashboardMetric(
        total: (json['total'] as num).toInt(),
        active: (json['active'] as num).toInt(),
        inactive: (json['inactive'] as num).toInt(),
      );
}

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.causes,
    required this.organisations,
    required this.beneficiaries,
  });
  final AdminDashboardMetric causes;
  final AdminDashboardMetric organisations;
  final AdminDashboardMetric beneficiaries;

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) =>
      AdminDashboardSummary(
        causes: AdminDashboardMetric.fromJson(json['causes'] as Map<String, dynamic>),
        organisations: AdminDashboardMetric.fromJson(json['organisations'] as Map<String, dynamic>),
        beneficiaries: AdminDashboardMetric.fromJson(json['beneficiaries'] as Map<String, dynamic>),
      );
}
