class AnalyticsSummary {
  final int viewClinic;
  final int viewDoctor;
  final int viewPharmacyBranch;
  final int callClicks;
  final int whatsappClicks;
  final int telegramClicks;
  final int routeClicks;
  final int favorites;
  final double avgRating;
  final int reviewsCount;

  const AnalyticsSummary({
    required this.viewClinic,
    required this.viewDoctor,
    required this.viewPharmacyBranch,
    required this.callClicks,
    required this.whatsappClicks,
    required this.telegramClicks,
    required this.routeClicks,
    required this.favorites,
    required this.avgRating,
    required this.reviewsCount,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    int i(String k) => (json[k] as num?)?.toInt() ?? 0;
    return AnalyticsSummary(
      viewClinic: i('view_clinic'),
      viewDoctor: i('view_doctor'),
      viewPharmacyBranch: i('view_pharmacy_branch'),
      callClicks: i('click_call'),
      whatsappClicks: i('click_whatsapp'),
      telegramClicks: i('click_telegram'),
      routeClicks: i('click_route'),
      favorites: i('add_favorite'),
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: i('reviews_count'),
    );
  }
}

class DoctorBreakdown {
  final int id;
  final String fullName;
  final String? photoUrl;
  final String? specialization;
  final int views;
  final int calls;
  final int whatsapp;
  final int telegram;

  const DoctorBreakdown({
    required this.id,
    required this.fullName,
    required this.views,
    required this.calls,
    required this.whatsapp,
    required this.telegram,
    this.photoUrl,
    this.specialization,
  });

  factory DoctorBreakdown.fromJson(Map<String, dynamic> json) {
    return DoctorBreakdown(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      specialization: json['specialization'] as String?,
      views: (json['views'] as num?)?.toInt() ?? 0,
      calls: (json['calls'] as num?)?.toInt() ?? 0,
      whatsapp: (json['whatsapp'] as num?)?.toInt() ?? 0,
      telegram: (json['telegram'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyPoint {
  final DateTime date;
  final int views;
  final int calls;
  final int whatsapp;

  const DailyPoint({
    required this.date,
    required this.views,
    required this.calls,
    required this.whatsapp,
  });

  factory DailyPoint.fromJson(Map<String, dynamic> json) {
    return DailyPoint(
      date: DateTime.parse(json['date'] as String),
      views: (json['views'] as num?)?.toInt() ?? 0,
      calls: (json['calls'] as num?)?.toInt() ?? 0,
      whatsapp: (json['whatsapp'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsReport {
  final DateTime from;
  final DateTime to;
  final AnalyticsSummary summary;
  final List<DoctorBreakdown> doctors;
  final List<DailyPoint> dailyTimeline;

  const AnalyticsReport({
    required this.from,
    required this.to,
    required this.summary,
    required this.doctors,
    required this.dailyTimeline,
  });

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>;
    return AnalyticsReport(
      from: DateTime.parse(period['from'] as String),
      to: DateTime.parse(period['to'] as String),
      summary: AnalyticsSummary.fromJson(json['summary'] as Map<String, dynamic>),
      doctors: (json['doctors'] as List? ?? [])
          .map((e) => DoctorBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyTimeline: (json['daily_timeline'] as List? ?? [])
          .map((e) => DailyPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
