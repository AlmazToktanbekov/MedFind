import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';

/// Универсальный экран ожидания проверки для doctor / clinic / pharmacy
class PendingReviewScreen extends StatelessWidget {
  final String providerType; // 'doctor' | 'clinic' | 'pharmacy'

  const PendingReviewScreen({
    super.key,
    this.providerType = 'doctor',
  });

  String get _title => switch (providerType) {
        'clinic' => 'Клиника на проверке',
        'pharmacy' => 'Аптека на проверке',
        _ => 'Профиль на проверке',
      };

  String get _subtitle => switch (providerType) {
        'clinic' =>
          'Данные вашей клиники отправлены на модерацию. Администратор проверит информацию и активирует профиль в течение 24 часов.',
        'pharmacy' =>
          'Данные вашей аптеки отправлены на модерацию. Администратор проверит информацию и активирует профиль в течение 24 часов.',
        _ =>
          'Ваш врачебный профиль отправлен в клинику на подтверждение. Как только клиника одобрит заявку, вы станете видны пациентам.',
      };

  Color get _accentColor => switch (providerType) {
        'clinic' => AppColors.success,
        'pharmacy' => AppColors.warning,
        _ => AppColors.primaryBlue,
      };

  IconData get _icon => switch (providerType) {
        'clinic' => PhosphorIconsFill.hospital,
        'pharmacy' => PhosphorIconsFill.pill,
        _ => PhosphorIconsFill.stethoscope,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          // Декоративный круг
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accentColor.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),

                  // Иконка с анимацией
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon, size: 52, color: _accentColor),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    _title,
                    style: AppTextStyles.headingLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _subtitle,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Карточка со статусами
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _StatusRow(
                          icon: PhosphorIconsFill.checkCircle,
                          color: AppColors.success,
                          text: 'Профиль создан',
                          isDone: true,
                        ),
                        const _Divider(),
                        _StatusRow(
                          icon: PhosphorIconsFill.clock,
                          color: AppColors.warning,
                          text: 'Ожидает подтверждения клиники',
                          isDone: false,
                        ),
                        const _Divider(),
                        _StatusRow(
                          icon: PhosphorIconsFill.bell,
                          color: AppColors.primaryBlue,
                          text: 'Вы станете видны пациентам после одобрения',
                          isDone: false,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  GradientButton(
                    text: 'Перейти на главную',
                    onPressed: () => context.go('/main'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool isDone;

  const _StatusRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.labelBold.copyWith(
              color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: AppColors.backgroundApp,
      ),
    );
  }
}
