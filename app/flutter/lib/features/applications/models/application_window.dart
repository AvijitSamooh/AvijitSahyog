enum ApplicationWindowStatus {
  scheduled,
  open,
  closed,
}

class ApplicationWindow {
  const ApplicationWindow({
    required this.type,
    required this.startsAt,
    required this.registrationEndsAt,
    required this.eventAt,
    required this.closedAt,
    required this.status,
    required this.canApply,
  });

  final String type;
  final DateTime startsAt;
  final DateTime? registrationEndsAt;
  final DateTime? eventAt;
  final DateTime? closedAt;
  final ApplicationWindowStatus status;
  final bool canApply;

  factory ApplicationWindow.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'CLOSED';
    final status = switch (rawStatus) {
      'SCHEDULED' => ApplicationWindowStatus.scheduled,
      'OPEN' => ApplicationWindowStatus.open,
      _ => ApplicationWindowStatus.closed,
    };

    return ApplicationWindow(
      type: json['type'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      registrationEndsAt: (json['registrationEndsAt'] as String?) == null
          ? null
          : DateTime.parse(json['registrationEndsAt'] as String),
      eventAt: (json['eventAt'] as String?) == null
          ? null
          : DateTime.parse(json['eventAt'] as String),
      closedAt: (json['closedAt'] as String?) == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
      status: status,
      canApply: json['canApply'] == true,
    );
  }

  bool get isOpen => status == ApplicationWindowStatus.open && canApply;
}
