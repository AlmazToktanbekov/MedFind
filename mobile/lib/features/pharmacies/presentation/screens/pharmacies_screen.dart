import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medfind/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../providers/pharmacies_provider.dart';

class PharmaciesScreen extends ConsumerStatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  ConsumerState<PharmaciesScreen> createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends ConsumerState<PharmaciesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    // Сбрасываем поисковый запрос при закрытии экрана
    ref.read(pharmacySearchQueryProvider.notifier).state = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mode = ref.watch(pharmacyListModeProvider);
    final isNearby = mode == PharmacyListMode.nearby;
    final searchQuery = ref.watch(pharmacySearchQueryProvider);
    final asyncData = isNearby
        ? ref.watch(nearbyBranchesProvider)
        : ref.watch(branchesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(l.pharmaciesTitle, style: AppTextStyles.headingMedium),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ─── Переключатель режима ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _ModeChip(
                  label: l.pharmaciesAll,
                  icon: PhosphorIconsRegular.pill,
                  isActive: !isNearby,
                  onTap: () => ref
                      .read(pharmacyListModeProvider.notifier)
                      .state = PharmacyListMode.all,
                ),
                const SizedBox(width: 10),
                _ModeChip(
                  label: l.pharmaciesNearby,
                  icon: PhosphorIconsRegular.navigationArrow,
                  isActive: isNearby,
                  onTap: () => ref
                      .read(pharmacyListModeProvider.notifier)
                      .state = PharmacyListMode.nearby,
                ),
              ],
            ),
          ),

          // ─── Поиск ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(pharmacySearchQueryProvider.notifier).state = v.trim(),
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Поиск по названию аптеки',
                hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          ref.read(pharmacySearchQueryProvider.notifier).state = '';
                        },
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFEEF2FF),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                ),
              ),
            ),
          ),

          // ─── Список ───────────────────────────────────────────────────
          Expanded(
            child: asyncData.when(
              loading: () => const _PharmaciesShimmer(),
              error: (err, _) => _ErrorView(
                error: err,
                onRetry: () => isNearby
                    ? ref.refresh(nearbyBranchesProvider)
                    : ref.refresh(branchesProvider),
              ),
              data: (allBranches) {
                final branches = searchQuery.isEmpty
                    ? allBranches
                    : allBranches
                        .where((b) =>
                            (b.companyName ?? '')
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase()))
                        .toList();

                if (branches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsRegular.pill,
                            size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Аптека не найдена'
                              : isNearby
                                  ? l.pharmaciesNearbyNotFound
                                  : l.pharmaciesNotFound,
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: branches.length,
                  itemBuilder: (_, i) => TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 200 + i * 40),
                    curve: Curves.easeOut,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                          offset: Offset(0, 12 * (1 - v)), child: child),
                    ),
                    child: GestureDetector(
                      onTap: () =>
                          context.push('/main/pharmacies/branch/${branches[i].id}'),
                      child: PharmacyBranchCard(branch: branches[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mode chip ─────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : AppColors.backgroundChip,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? Colors.white : AppColors.primaryBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelBold.copyWith(
                color: isActive ? Colors.white : AppColors.primaryBlue,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Branch card ───────────────────────────────────────────────────────────

class PharmacyBranchCard extends StatelessWidget {
  final PharmacyBranchModel branch;
  final String? fallbackLogoUrl;

  const PharmacyBranchCard({super.key, required this.branch, this.fallbackLogoUrl});

  Future<void> _call() async {
    if (branch.phone == null) return;
    final uri = Uri.parse('tel:${branch.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Лого / фото
          _BranchThumb(branch: branch, fallbackLogoUrl: fallbackLogoUrl),
          const SizedBox(width: 12),
          // Инфо
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (branch.companyName != null)
                  Text(
                    branch.companyName!,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (branch.address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.mapPin,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(branch.address!,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                if (branch.workingHours != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.clock,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(branch.workingHours!,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                if (branch.distanceKm != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    AppLocalizations.of(context).pharmaciesDistanceFromYou(
                        branch.distanceKm!.toStringAsFixed(1)),
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
          if (branch.phone != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _call,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.phone,
                    color: AppColors.primaryBlue, size: 17),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BranchThumb extends StatelessWidget {
  final PharmacyBranchModel branch;
  final String? fallbackLogoUrl;
  const _BranchThumb({required this.branch, this.fallbackLogoUrl});

  @override
  Widget build(BuildContext context) {
    // Все филиалы показывают логотип компании, заданный в главном профиле.
    final imageUrl = branch.companyLogoUrl ?? fallbackLogoUrl;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.backgroundChip,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (ctx, e, s) => const _PillPlaceholder(),
            )
          : const _PillPlaceholder(),
    );
  }
}

class _PillPlaceholder extends StatelessWidget {
  const _PillPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(PhosphorIconsRegular.pill,
        color: AppColors.primaryBlue, size: 24);
  }
}

// ─── Error view ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final err = error;
    final isLocation = err is LocationException;
    final message = err is LocationException
        ? switch (err.kind) {
            LocationErrorKind.serviceDisabled => l.locationServiceDisabled,
            LocationErrorKind.denied => l.locationPermissionDenied,
            LocationErrorKind.deniedForever => l.locationPermissionDeniedForever,
          }
        : err.toString().replaceAll('Exception: ', '');
    final icon = isLocation
        ? PhosphorIconsRegular.mapPin
        : PhosphorIconsRegular.wifiX;

    Future<void> primaryAction() async {
      if (err is LocationException) {
        switch (err.kind) {
          case LocationErrorKind.serviceDisabled:
            await Geolocator.openLocationSettings();
            return;
          case LocationErrorKind.deniedForever:
            await Geolocator.openAppSettings();
            return;
          case LocationErrorKind.denied:
            break;
        }
      }
      onRetry();
    }

    final primaryLabel = (err is LocationException)
        ? switch (err.kind) {
            LocationErrorKind.serviceDisabled => l.locationEnableGeo,
            LocationErrorKind.deniedForever => l.locationOpenSettings,
            LocationErrorKind.denied => l.locationAllow,
          }
        : l.commonRetry;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: primaryAction,
              child: Text(primaryLabel, style: AppTextStyles.labelBold),
            ),
            if (isLocation && err.kind != LocationErrorKind.denied)
              TextButton(
                onPressed: onRetry,
                child: Text(l.commonRetry,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ───────────────────────────────────────────────────────────────

class _PharmaciesShimmer extends StatelessWidget {
  const _PharmaciesShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: 6,
        itemBuilder: (ctx, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 86,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
