class RetentionCohort {
  const RetentionCohort({required this.cohort, required this.users, required this.day1Percent, required this.day7Percent, required this.day30Percent});
  final String cohort;
  final int users;
  final double day1Percent;
  final double day7Percent;
  final double day30Percent;
  factory RetentionCohort.fromJson(Map<String, dynamic> json) => RetentionCohort(cohort: json['cohort'] as String, users: (json['users'] as num).toInt(), day1Percent: (json['day1Percent'] as num).toDouble(), day7Percent: (json['day7Percent'] as num).toDouble(), day30Percent: (json['day30Percent'] as num).toDouble());
}

class EngagementCohort {
  const EngagementCohort({required this.cohort, required this.users, required this.sessions, required this.interactions, required this.sessionsPerUser});
  final String cohort;
  final int users;
  final int sessions;
  final int interactions;
  final double sessionsPerUser;
  factory EngagementCohort.fromJson(Map<String, dynamic> json) => EngagementCohort(cohort: json['cohort'] as String, users: (json['users'] as num).toInt(), sessions: (json['sessions'] as num).toInt(), interactions: (json['interactions'] as num).toInt(), sessionsPerUser: (json['sessionsPerUser'] as num).toDouble());
}

class FeatureAdoption {
  const FeatureAdoption({required this.feature, required this.users, required this.events, required this.adoptionPercent});
  final String feature;
  final int users;
  final int events;
  final double adoptionPercent;
  factory FeatureAdoption.fromJson(Map<String, dynamic> json) => FeatureAdoption(feature: json['feature'] as String, users: (json['users'] as num).toInt(), events: (json['events'] as num).toInt(), adoptionPercent: (json['adoptionPercent'] as num).toDouble());
}

class AnalyticsSegment {
  const AnalyticsSegment({required this.segment, required this.users, required this.events, required this.sharePercent});
  final String segment;
  final int users;
  final int events;
  final double sharePercent;
  factory AnalyticsSegment.fromJson(Map<String, dynamic> json) => AnalyticsSegment(segment: json['segment'] as String, users: (json['users'] as num).toInt(), events: (json['events'] as num).toInt(), sharePercent: (json['sharePercent'] as num).toDouble());
}

class AnalyticsSegmentation {
  const AnalyticsSegmentation({required this.city, required this.language, required this.device});
  final List<AnalyticsSegment> city;
  final List<AnalyticsSegment> language;
  final List<AnalyticsSegment> device;
  factory AnalyticsSegmentation.fromJson(Map<String, dynamic> json) => AnalyticsSegmentation(city: _segments(json['city']), language: _segments(json['language']), device: _segments(json['device']));
  static List<AnalyticsSegment> _segments(dynamic value) => (value as List<dynamic>).map((item) => AnalyticsSegment.fromJson(item as Map<String, dynamic>)).toList(growable: false);
}

class AdvancedAnalyticsSummary {
  const AdvancedAnalyticsSummary({required this.retention, required this.engagementCohorts, required this.featureAdoption, required this.segmentation, required this.cohortUsers, required this.mau, required this.bigQueryReady});
  final List<RetentionCohort> retention;
  final List<EngagementCohort> engagementCohorts;
  final List<FeatureAdoption> featureAdoption;
  final AnalyticsSegmentation segmentation;
  final int cohortUsers;
  final int mau;
  final bool bigQueryReady;
  factory AdvancedAnalyticsSummary.fromJson(Map<String, dynamic> json) => AdvancedAnalyticsSummary(retention: _retention(json['retention']), engagementCohorts: _engagement(json['engagementCohorts']), featureAdoption: _features(json['featureAdoption']), segmentation: AnalyticsSegmentation.fromJson(json['segmentation'] as Map<String, dynamic>), cohortUsers: (json['cohortUsers'] as num).toInt(), mau: (json['mau'] as num).toInt(), bigQueryReady: (json['warehouse'] as Map<String, dynamic>)['bigQueryReady'] == true);
  static List<RetentionCohort> _retention(dynamic value) => (value as List<dynamic>).map((item) => RetentionCohort.fromJson(item as Map<String, dynamic>)).toList(growable: false);
  static List<EngagementCohort> _engagement(dynamic value) => (value as List<dynamic>).map((item) => EngagementCohort.fromJson(item as Map<String, dynamic>)).toList(growable: false);
  static List<FeatureAdoption> _features(dynamic value) => (value as List<dynamic>).map((item) => FeatureAdoption.fromJson(item as Map<String, dynamic>)).toList(growable: false);
}
