import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/analytics_models.dart';

enum TimelineMetric { views, calls, whatsapp }

class TimelineChart extends StatefulWidget {
  final List<DailyPoint> points;
  const TimelineChart({super.key, required this.points});

  @override
  State<TimelineChart> createState() => _TimelineChartState();
}

class _TimelineChartState extends State<TimelineChart> {
  TimelineMetric _metric = TimelineMetric.views;

  int _value(DailyPoint p) {
    switch (_metric) {
      case TimelineMetric.views:
        return p.views;
      case TimelineMetric.calls:
        return p.calls;
      case TimelineMetric.whatsapp:
        return p.whatsapp;
    }
  }

  String get _label {
    switch (_metric) {
      case TimelineMetric.views:
        return 'Просмотры';
      case TimelineMetric.calls:
        return 'Звонки';
      case TimelineMetric.whatsapp:
        return 'WhatsApp';
    }
  }

  Color get _color {
    switch (_metric) {
      case TimelineMetric.views:
        return AppColors.primaryBlue;
      case TimelineMetric.calls:
        return const Color(0xFF00C897);
      case TimelineMetric.whatsapp:
        return const Color(0xFF25D366);
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final hasData = points.any((p) => _value(p) > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Активность по дням',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              DropdownButton<TimelineMetric>(
                value: _metric,
                underline: const SizedBox(),
                onChanged: (v) {
                  if (v != null) setState(() => _metric = v);
                },
                items: const [
                  DropdownMenuItem(value: TimelineMetric.views, child: Text('Просмотры')),
                  DropdownMenuItem(value: TimelineMetric.calls, child: Text('Звонки')),
                  DropdownMenuItem(value: TimelineMetric.whatsapp, child: Text('WhatsApp')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: !hasData
                ? Center(
                    child: Text(
                      'Пока нет данных за этот период',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textPrimary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: (points.length / 6).ceilToDouble().clamp(1, 999),
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= points.length) return const SizedBox();
                              final d = points[i].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${d.day}.${d.month}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < points.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: _value(points[i]).toDouble(),
                                color: _color,
                                width: 8,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            _label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textPrimary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
