import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../../pharmacies/presentation/screens/pharmacy_manage_screen.dart';
import '../../data/analytics_models.dart';
import '../../providers/analytics_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/timeline_chart.dart';

class PharmacyBranchAnalyticsScreen extends ConsumerStatefulWidget {
  const PharmacyBranchAnalyticsScreen({super.key});

  @override
  ConsumerState<PharmacyBranchAnalyticsScreen> createState() =>
      _PharmacyBranchAnalyticsScreenState();
}

class _PharmacyBranchAnalyticsScreenState
    extends ConsumerState<PharmacyBranchAnalyticsScreen> {
  late DateRange _range;
  int? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateRange(
      from: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30)),
      to: DateTime(now.year, now.month, now.day),
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _range.from, end: _range.to),
    );
    if (picked != null) {
      setState(() => _range = DateRange(from: picked.start, to: picked.end));
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(myPharmacyCompanyProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Отчёты по филиалам',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (company) {
          if (company == null || company.branches.isEmpty) {
            return Center(
              child: Text(
                'У вас пока нет филиалов',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }
          _selectedBranchId ??= company.branches.first.id;
          final branch = company.branches.firstWhere(
            (b) => b.id == _selectedBranchId,
            orElse: () => company.branches.first,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BranchSelector(
                branches: company.branches,
                selectedId: _selectedBranchId!,
                onChanged: (id) => setState(() => _selectedBranchId = id),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickRange,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.calendar,
                          color: AppColors.primaryBlue),
                      const SizedBox(width: 10),
                      Text(
                        '${_fmt(_range.from)} — ${_fmt(_range.to)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _BranchReport(branchId: branch.id, range: _range),
            ],
          );
        },
      ),
    );
  }
}

class _BranchSelector extends StatelessWidget {
  final List<PharmacyBranchModel> branches;
  final int selectedId;
  final ValueChanged<int> onChanged;
  const _BranchSelector({
    required this.branches,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: selectedId,
          icon: const Icon(PhosphorIconsRegular.caretDown,
              color: AppColors.primaryBlue),
          items: branches
              .map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(
                      b.address ?? 'Филиал #${b.id}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _BranchReport extends ConsumerWidget {
  final int branchId;
  final DateRange range;
  const _BranchReport({required this.branchId, required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = BranchReportKey(branchId: branchId, range: range);
    final reportAsync = ref.watch(branchAnalyticsProvider(key));

    return reportAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              Icon(
                PhosphorIconsRegular.warning,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Не удалось загрузить отчёт',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
      data: (report) => _BranchReportBody(report: report),
    );
  }
}

class _BranchReportBody extends StatelessWidget {
  final AnalyticsReport report;
  const _BranchReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final s = report.summary;
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            MetricCard(
              icon: PhosphorIconsRegular.eye,
              label: 'Просмотры',
              value: s.viewPharmacyBranch.toString(),
            ),
            MetricCard(
              icon: PhosphorIconsRegular.phone,
              label: 'Звонки',
              value: s.callClicks.toString(),
              color: const Color(0xFF00C897),
            ),
            MetricCard(
              icon: PhosphorIconsRegular.whatsappLogo,
              label: 'WhatsApp',
              value: s.whatsappClicks.toString(),
              color: const Color(0xFF25D366),
            ),
            MetricCard(
              icon: PhosphorIconsRegular.mapPin,
              label: 'Маршрут',
              value: s.routeClicks.toString(),
              color: const Color(0xFFFF8C42),
            ),
            MetricCard(
              icon: PhosphorIconsRegular.heart,
              label: 'В избранное',
              value: s.favorites.toString(),
              color: const Color(0xFFE53935),
            ),
            MetricCard(
              icon: PhosphorIconsRegular.star,
              label: 'Рейтинг',
              value: s.avgRating.toStringAsFixed(1),
              color: const Color(0xFFFFB300),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TimelineChart(points: report.dailyTimeline),
        const SizedBox(height: 32),
      ],
    );
  }
}
