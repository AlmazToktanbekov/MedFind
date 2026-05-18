import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../pharmacies/data/pharmacies_repository.dart';
import '../../../../shared/models/pharmacy_model.dart';

class _BranchCard extends StatelessWidget {
  final PharmacyBranchModel branch;
  final VoidCallback onTap;
  final VoidCallback? onPhotos;
  final VoidCallback? onEdit;

  const _BranchCard({
    required this.branch,
    required this.onTap,
    this.onPhotos,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(PhosphorIconsRegular.mapPin,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.address ?? 'Адрес не указан',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (branch.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      branch.phone!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  if (branch.workingHours != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      branch.workingHours!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: branch.isActive
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    branch.isActive ? 'Активен' : 'Откл.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: branch.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(PhosphorIconsRegular.pencilSimple,
                        color: AppColors.warning, size: 20),
                  ),
                ],
                if (onPhotos != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onPhotos,
                    child: const Icon(PhosphorIconsRegular.images,
                        color: AppColors.primaryBlue, size: 20),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final _pharmacyRepoProvider =
    Provider<PharmaciesRepository>((_) => PharmaciesRepository());

final myPharmacyCompanyProvider =
    FutureProvider<PharmacyCompanyModel?>((ref) async {
  return ref.read(_pharmacyRepoProvider).getMyCompany();
});

class PharmacyManageScreen extends ConsumerWidget {
  const PharmacyManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(myPharmacyCompanyProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        title: Text('Моя аптека', style: AppTextStyles.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.house,
                color: AppColors.warning),
            onPressed: () => context.go('/main'),
          ),
        ],
      ),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text('Ошибка загрузки',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary)),
        ),
        data: (company) {
          if (company == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsRegular.pill,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Аптека не найдена',
                      style: AppTextStyles.headingMedium),
                  const SizedBox(height: 8),
                  Text('Зарегистрируйте аптеку',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.go('/provider/pharmacy-setup'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.btnGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Зарегистрировать аптеку',
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
              // Company header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: company.logoUrl != null
                          ? ClipOval(
                              child: Image.network(company.logoUrl!,
                                  fit: BoxFit.cover))
                          : const Icon(PhosphorIconsRegular.pill,
                              color: AppColors.warning, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: AppTextStyles.headingMedium,
                          ),
                          Text(
                            '${company.branches.length} филиал(ов)',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
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

              _MenuItem(
                icon: PhosphorIconsRegular.pencilSimple,
                title: 'Редактировать профиль',
                subtitle: 'Название, логотип, контакты',
                color: AppColors.warning,
                onTap: () => context.push('/provider/pharmacy/edit'),
              ),

              const SizedBox(height: 8),

              // ── Заголовок филиалов ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Филиалы',
                      style: AppTextStyles.headingMedium),
                  GestureDetector(
                    onTap: () =>
                        context.push('/provider/pharmacy/branch/add'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.btnGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIconsRegular.plus,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text('Добавить',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Карточки филиалов ────────────────────────────────────
              if (company.branches.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Center(
                    child: Text(
                      'Нет добавленных филиалов',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...company.branches.map((branch) => _BranchCard(
                      branch: branch,
                      onTap: () => context
                          .push('/main/pharmacies/branch/${branch.id}'),
                      onEdit: () => context.push(
                          '/provider/pharmacy/branch/${branch.id}/edit'),
                      onPhotos: () => context
                          .push('/pharmacy/branch/${branch.id}/photos'),
                    )),
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
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyLarge
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

