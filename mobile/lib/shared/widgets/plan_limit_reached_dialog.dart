import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';

/// Модалка, которая показывается при HTTP 402 (plan_limit_reached).
/// limitType: "doctors" | "branches"
class PlanLimitReachedDialog extends StatelessWidget {
  final String limitType;
  final int limit;
  final String currentPlan;

  const PlanLimitReachedDialog({
    super.key,
    required this.limitType,
    required this.limit,
    required this.currentPlan,
  });

  static Future<void> show(
    BuildContext context, {
    required String limitType,
    required int limit,
    required String currentPlan,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PlanLimitReachedDialog(
        limitType: limitType,
        limit: limit,
        currentPlan: currentPlan,
      ),
    );
  }

  String get _entity => limitType == 'doctors' ? 'врачей' : 'филиалов';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsFill.crown,
                  color: AppColors.primaryBlue,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Достигнут лимит',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'На бесплатном тарифе доступно до $limit $_entity.\nОформите подписку, чтобы добавить больше.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _PlanRow(
              title: 'Pro',
              price: '\$20 / мес',
              subtitle: 'Неограниченно $_entity',
              color: AppColors.primaryBlue,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/subscription');
              },
            ),
            const SizedBox(height: 10),
            _PlanRow(
              title: 'Premium',
              price: '\$40 / мес',
              subtitle: 'Без лимитов + отчёты + бейдж',
              color: const Color(0xFFFFB300),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/subscription');
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Может позже',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PlanRow({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        price,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(PhosphorIconsRegular.caretRight, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
