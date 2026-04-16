import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/clinic_model.dart';
import '../../../../shared/widgets/filter_chip_widget.dart';
import '../../providers/clinics_provider.dart';

class ClinicsScreen extends ConsumerWidget {
  const ClinicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(clinicCategoryProvider);
    final clinicsAsync = ref.watch(clinicsProvider(category));

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Клиники', style: AppTextStyles.headingMedium),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Фильтр по категориям
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChipWidget(
                    label: 'Все',
                    isActive: category == null,
                    onTap: () =>
                        ref.read(clinicCategoryProvider.notifier).state = null,
                  ),
                ),
                ...AppConstants.clinicCategories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChipWidget(
                      label: cat,
                      isActive: category == cat,
                      onTap: () =>
                          ref.read(clinicCategoryProvider.notifier).state = cat,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: clinicsAsync.when(
              loading: () => const _ClinicsShimmer(),
              error: (_, __) => _ErrorView(
                onRetry: () => ref.refresh(clinicsProvider(category)),
              ),
              data: (clinics) {
                if (clinics.isEmpty) return const _EmptyView();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clinics.length,
                  itemBuilder: (_, index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 250 + index * 50),
                      curve: Curves.easeOut,
                      builder: (context, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - v)),
                          child: child,
                        ),
                      ),
                      child: ClinicCard(
                        clinic: clinics[index],
                        onTap: () =>
                            context.push('/main/clinics/${clinics[index].id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clinic card ───────────────────────────────────────────────────────────

class ClinicCard extends StatelessWidget {
  final ClinicModel clinic;
  final VoidCallback onTap;

  const ClinicCard({super.key, required this.clinic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            // Фото
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.backgroundChip,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: clinic.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: clinic.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const _ClinicIcon(),
                    )
                  : const _ClinicIcon(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (clinic.category != null)
                    Text(clinic.category!,
                        style: AppTextStyles.labelBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    clinic.name,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (clinic.address != null)
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.mapPin,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            clinic.address!,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFB300), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        clinic.rating.toStringAsFixed(1),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('(${clinic.reviewsCount})',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsRegular.arrowRight,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicIcon extends StatelessWidget {
  const _ClinicIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(PhosphorIconsRegular.hospital,
        color: AppColors.primaryBlue, size: 30);
  }
}

class _ClinicsShimmer extends StatelessWidget {
  const _ClinicsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('Не удалось загрузить клиники',
              style:
                  AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
          TextButton(
            onPressed: onRetry,
            child: Text('Повторить', style: AppTextStyles.labelBold),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Клиники не найдены',
          style:
              AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
    );
  }
}
