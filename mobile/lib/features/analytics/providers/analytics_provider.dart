import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_models.dart';
import '../data/analytics_repository.dart';

class DateRange {
  final DateTime from;
  final DateTime to;
  const DateRange({required this.from, required this.to});

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

class BranchReportKey {
  final int branchId;
  final DateRange range;
  const BranchReportKey({required this.branchId, required this.range});

  @override
  bool operator ==(Object other) =>
      other is BranchReportKey && other.branchId == branchId && other.range == range;

  @override
  int get hashCode => Object.hash(branchId, range);
}

final analyticsRepositoryProvider =
    Provider<AnalyticsRepository>((_) => AnalyticsRepository());

final clinicAnalyticsProvider =
    FutureProvider.family<AnalyticsReport, DateRange>((ref, range) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getClinicReport(from: range.from, to: range.to);
});

final branchAnalyticsProvider =
    FutureProvider.family<AnalyticsReport, BranchReportKey>((ref, key) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getBranchReport(
    branchId: key.branchId,
    from: key.range.from,
    to: key.range.to,
  );
});
