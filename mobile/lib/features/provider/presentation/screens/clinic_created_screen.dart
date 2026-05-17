import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';

/// Экран-подтверждение после успешной регистрации клиники.
class ClinicCreatedScreen extends StatelessWidget {
  const ClinicCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundApp,
        body: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.success.withValues(alpha: 0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(),
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
                          color: AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(PhosphorIconsFill.checkCircle,
                            size: 54, color: AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Профиль клиники создан!',
                        style: AppTextStyles.headingLarge,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'Ваша клиника уже видна пациентам. Теперь добавьте врачей и заполните остальные данные.',
                      style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary, height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Что дальше',
                              style: AppTextStyles.labelBold
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 14),
                          const _StepRow(
                            n: 1,
                            text: 'Врачи подадут заявку в вашу клинику — подтвердите их в разделе «Управление врачами»',
                          ),
                          const _StepRow(
                            n: 2,
                            text: 'Загрузите фото клиники',
                          ),
                          const _StepRow(
                            n: 3,
                            text: 'Проверьте контакты, адрес и график работы',
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GradientButton(
                      text: 'Перейти в кабинет клиники',
                      onPressed: () => context.go('/main'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/main'),
                      child: Text('На главную',
                          style: AppTextStyles.labelBold
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int n;
  final String text;
  final bool last;
  const _StepRow({required this.n, required this.text, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$n',
                  style: AppTextStyles.labelBold.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textPrimary, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}
