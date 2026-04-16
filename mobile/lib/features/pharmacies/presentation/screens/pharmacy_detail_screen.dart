import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/pharmacies_provider.dart';
import '../../../../shared/models/pharmacy_model.dart';

class PharmacyDetailScreen extends ConsumerWidget {
  final String pharmacyId;
  const PharmacyDetailScreen({super.key, required this.pharmacyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(pharmacyId) ?? 0;
    final pharmacyAsync = ref.watch(pharmacyByIdProvider(id));

    return pharmacyAsync.when(
      loading: () => const _DetailShimmer(),
      error: (_, __) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('Не удалось загрузить аптеку',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.refresh(pharmacyByIdProvider(id)),
                child: Text('Повторить', style: AppTextStyles.labelBold),
              ),
            ],
          ),
        ),
      ),
      data: (pharmacy) => _PharmacyDetailBody(pharmacy: pharmacy),
    );
  }
}

class _PharmacyDetailBody extends StatelessWidget {
  final PharmacyModel pharmacy;
  const _PharmacyDetailBody({required this.pharmacy});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image or gradient
                  pharmacy.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: pharmacy.photoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const _GradientBg(),
                        )
                      : const _GradientBg(),
                  // Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primaryDark.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  // Name + badges
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Аптека',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (pharmacy.isOpen24h) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB800)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Круглосуточно',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFFFFB800),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pharmacy.name,
                          style: AppTextStyles.headingMedium
                              .copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards
                  _InfoCard(children: [
                    if (pharmacy.address != null)
                      _InfoRow(
                        icon: PhosphorIconsRegular.mapPin,
                        label: 'Адрес',
                        value: pharmacy.address!,
                        color: AppColors.primaryBlue,
                      ),
                    if (pharmacy.workingHours != null && !pharmacy.isOpen24h)
                      _InfoRow(
                        icon: PhosphorIconsRegular.clock,
                        label: 'Время работы',
                        value: pharmacy.workingHours!,
                        color: AppColors.accentBlue,
                      ),
                    if (pharmacy.isOpen24h)
                      _InfoRow(
                        icon: PhosphorIconsRegular.clock,
                        label: 'Время работы',
                        value: 'Круглосуточно',
                        color: AppColors.success,
                      ),
                    if (pharmacy.distanceKm != null)
                      _InfoRow(
                        icon: PhosphorIconsRegular.navigationArrow,
                        label: 'Расстояние',
                        value:
                            '${pharmacy.distanceKm!.toStringAsFixed(1)} км от вас',
                        color: AppColors.warning,
                      ),
                  ]),

                  // Contacts
                  if (pharmacy.phone != null) ...[
                    const SizedBox(height: 20),
                    Text('Контакты', style: AppTextStyles.headingMedium),
                    const SizedBox(height: 12),
                    _ContactTile(
                      icon: PhosphorIconsRegular.phone,
                      label: pharmacy.phone!,
                      color: AppColors.primaryBlue,
                      onTap: () => _openUrl('tel:${pharmacy.phone}'),
                    ),
                  ],

                  // Map button
                  if (pharmacy.latitude != null &&
                      pharmacy.longitude != null) ...[
                    const SizedBox(height: 12),
                    _ContactTile(
                      icon: PhosphorIconsRegular.mapTrifold,
                      label: 'Открыть на карте',
                      color: AppColors.success,
                      onTap: () => _openUrl(
                          'geo:${pharmacy.latitude},${pharmacy.longitude}?q=${pharmacy.name}'),
                    ),
                  ],

                  const SizedBox(height: 32),
                  if (pharmacy.phone != null)
                    GradientButton(
                      text: 'Позвонить',
                      onPressed: () => _openUrl('tel:${pharmacy.phone}'),
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

// ─── Info card ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              const SizedBox(height: 2),
              Text(value,
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Contact tile ──────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient background ───────────────────────────────────────────────────

class _GradientBg extends StatelessWidget {
  const _GradientBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: Icon(PhosphorIconsRegular.pill,
            color: Colors.white.withValues(alpha: 0.3), size: 72),
      ),
    );
  }
}

// ─── Detail shimmer ────────────────────────────────────────────────────────

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Container(height: 220, color: Colors.white),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
