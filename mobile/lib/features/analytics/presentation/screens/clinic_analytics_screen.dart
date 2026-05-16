import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/analytics_models.dart';
import '../../providers/analytics_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/timeline_chart.dart';

class ClinicAnalyticsScreen extends ConsumerStatefulWidget {
  const ClinicAnalyticsScreen({super.key});

  @override
  ConsumerState<ClinicAnalyticsScreen> createState() =>
      _ClinicAnalyticsScreenState();
}

class _ClinicAnalyticsScreenState extends ConsumerState<ClinicAnalyticsScreen> {
  late DateRange _range;

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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(clinicAnalyticsProvider(_range));

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Отчёты',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(clinicAnalyticsProvider(_range)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PeriodBar(
              from: _range.from,
              to: _range.to,
              onTap: _pickRange,
              format: _fmtDate,
            ),
            const SizedBox(height: 16),
            reportAsync.when(
              data: (report) => _ReportBody(report: report),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorBox(error: e),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final VoidCallback onTap;
  final String Function(DateTime) format;
  const _PeriodBar({
    required this.from,
    required this.to,
    required this.onTap,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            const Icon(PhosphorIconsRegular.calendar, color: AppColors.primaryBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Период',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    '${format(from)} — ${format(to)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final AnalyticsReport report;
  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final s = report.summary;
    final views = s.viewClinic + s.viewDoctor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              value: views.toString(),
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
              icon: PhosphorIconsRegular.telegramLogo,
              label: 'Telegram',
              value: s.telegramClicks.toString(),
              color: const Color(0xFF0088CC),
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
            MetricCard(
              icon: PhosphorIconsRegular.chatCircle,
              label: 'Отзывы',
              value: s.reviewsCount.toString(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TimelineChart(points: report.dailyTimeline),
        const SizedBox(height: 16),
        if (report.doctors.isNotEmpty) ...[
          Text(
            'Топ врачей',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...report.doctors.take(10).map((d) => _DoctorRow(doctor: d)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _DoctorRow extends StatelessWidget {
  final DoctorBreakdown doctor;
  const _DoctorRow({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: doctor.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: doctor.photoUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _ph(),
                  )
                : _ph(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.fullName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (doctor.specialization != null)
                  Text(
                    doctor.specialization!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniStat(icon: PhosphorIconsRegular.eye, value: doctor.views),
                    const SizedBox(width: 12),
                    _MiniStat(icon: PhosphorIconsRegular.phone, value: doctor.calls),
                    const SizedBox(width: 12),
                    _MiniStat(icon: PhosphorIconsRegular.whatsappLogo, value: doctor.whatsapp),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ph() => Container(
        width: 48,
        height: 48,
        color: AppColors.backgroundApp,
        child: const Icon(PhosphorIconsRegular.user, color: AppColors.textSecondary),
      );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int value;
  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textPrimary.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final Object error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    final isPremiumRequired = error.toString().contains('premium_required');
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
            isPremiumRequired ? PhosphorIconsFill.crown : PhosphorIconsRegular.warning,
            size: 48,
            color: isPremiumRequired ? const Color(0xFFFFB300) : AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            isPremiumRequired
                ? 'Отчёты доступны на тарифе Premium'
                : 'Не удалось загрузить отчёт',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (isPremiumRequired) ...[
            const SizedBox(height: 8),
            Text(
              'Оформите Premium, чтобы видеть просмотры, звонки и активность пациентов',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
