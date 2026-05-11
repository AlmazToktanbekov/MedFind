import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../clinics/data/clinics_repository.dart';
import '../../../../shared/models/clinic_model.dart';

// ─── Provider ──────────────────────────────────────────────────────────────

final _clinicsRepoProvider =
    Provider<ClinicsRepository>((_) => ClinicsRepository());

final myClinicProvider = FutureProvider<ClinicModel?>((ref) async {
  return ref.read(_clinicsRepoProvider).getMyClinic();
});

// ─── Screen ────────────────────────────────────────────────────────────────

class ClinicManageScreen extends ConsumerWidget {
  const ClinicManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicAsync = ref.watch(myClinicProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        title: Text('Моя клиника', style: AppTextStyles.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.house,
                color: AppColors.primaryBlue),
            onPressed: () => context.go('/main'),
          ),
        ],
      ),
      body: clinicAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text('Ошибка загрузки',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary)),
        ),
        data: (clinic) {
          if (clinic == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsRegular.hospital,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Клиника не найдена',
                      style: AppTextStyles.headingMedium),
                  const SizedBox(height: 8),
                  Text('Зарегистрируйте клинику',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.go('/provider/clinic-intro'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.btnGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Зарегистрировать клинику',
                        style: AppTextStyles.labelBold
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Clinic header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: clinic.logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: clinic.logoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const Icon(
                                  PhosphorIconsRegular.hospital,
                                  color: Colors.white,
                                  size: 28),
                            )
                          : const Icon(PhosphorIconsRegular.hospital,
                              color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinic.name,
                            style: AppTextStyles.headingMedium
                                .copyWith(color: Colors.white),
                          ),
                          if (clinic.category != null)
                            Text(
                              clinic.category!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Активна',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Menu items
              _MenuItem(
                icon: PhosphorIconsRegular.pencilSimple,
                title: 'Редактировать профиль',
                subtitle: 'Информация, контакты, фото',
                onTap: () =>
                    context.push('/clinic/${clinic.id}/edit'),
              ),
              _MenuItem(
                icon: PhosphorIconsRegular.userList,
                title: 'Врачи клиники',
                subtitle: 'Список подтверждённых врачей',
                onTap: () =>
                    context.push('/clinic/${clinic.id}/doctors'),
              ),
              _MenuItem(
                icon: PhosphorIconsRegular.clockCounterClockwise,
                title: 'Заявки врачей',
                subtitle: 'Управление заявками: ожидают / активны / отклонены',
                onTap: () =>
                    context.push('/clinic/${clinic.id}/doctor-requests'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
