import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';

/// Экран-объяснение перед регистрацией клиники: что даёт профиль и как он работает.
class ClinicIntroScreen extends StatelessWidget {
  const ClinicIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft,
              color: AppColors.textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/main'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsFill.hospital,
                    size: 46, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 24),
              Text('Регистрация клиники',
                  style: AppTextStyles.headingLarge, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'Бесплатно. 3 коротких шага: данные клиники → контакты и адрес → фото.',
                style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const Column(
                  children: [
                    _FeatureRow(
                      icon: PhosphorIconsFill.eye,
                      text: 'Профиль клиники виден пациентам сразу после регистрации — модерация не нужна',
                    ),
                    _Divider(),
                    _FeatureRow(
                      icon: PhosphorIconsFill.stethoscope,
                      text: 'Управляйте врачами: подтверждайте заявки, активируйте и деактивируйте',
                    ),
                    _Divider(),
                    _FeatureRow(
                      icon: PhosphorIconsFill.images,
                      text: 'Добавляйте фото, направления, контакты и график работы',
                    ),
                    _Divider(),
                    _FeatureRow(
                      icon: PhosphorIconsFill.star,
                      text: 'Получайте отзывы пациентов',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GradientButton(
                text: 'Начать регистрацию',
                onPressed: () => context.push('/provider/clinic-setup'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textPrimary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 24, thickness: 1, color: Color(0xFFEEF2FF));
}
