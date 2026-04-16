import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../providers/pharmacies_provider.dart';

class PharmaciesScreen extends ConsumerWidget {
  const PharmaciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmaciesAsync = ref.watch(pharmaciesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Аптеки', style: AppTextStyles.headingMedium),
        centerTitle: false,
      ),
      body: pharmaciesAsync.when(
        loading: () => const _PharmaciesShimmer(),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('Не удалось загрузить аптеки',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.refresh(pharmaciesProvider),
                child: Text('Повторить', style: AppTextStyles.labelBold),
              ),
            ],
          ),
        ),
        data: (pharmacies) {
          if (pharmacies.isEmpty) {
            return Center(
              child: Text('Аптеки не найдены',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pharmacies.length,
            itemBuilder: (_, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 250 + index * 50),
                curve: Curves.easeOut,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child:
                      Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
                ),
                child: GestureDetector(
                  onTap: () => context.push(
                      '/main/pharmacies/${pharmacies[index].id}'),
                  child: PharmacyCard(pharmacy: pharmacies[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Pharmacy card ─────────────────────────────────────────────────────────

class PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;

  const PharmacyCard({super.key, required this.pharmacy});

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Иконка / фото
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.backgroundChip,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: pharmacy.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: pharmacy.photoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _PillIcon(),
                  )
                : const _PillIcon(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pharmacy.name,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pharmacy.isOpen24h)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '24ч',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                if (pharmacy.address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.mapPin,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pharmacy.address!,
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (pharmacy.workingHours != null && !pharmacy.isOpen24h) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.clock,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pharmacy.workingHours!,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (pharmacy.distanceKm != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${pharmacy.distanceKm!.toStringAsFixed(1)} км от вас',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Кнопка звонка
          if (pharmacy.phone != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _call(pharmacy.phone!),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.phone,
                    color: AppColors.primaryBlue, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillIcon extends StatelessWidget {
  const _PillIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(PhosphorIconsRegular.pill,
        color: AppColors.primaryBlue, size: 28);
  }
}

class _PharmaciesShimmer extends StatelessWidget {
  const _PharmaciesShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 88,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
