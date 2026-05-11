import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../../../shared/widgets/doctor_card.dart';
import '../../../../features/doctors/providers/doctors_provider.dart';
import '../../../../features/clinics/providers/clinics_provider.dart';
import '../../../../features/pharmacies/providers/pharmacies_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final doctorCount = favorites.where((k) => k.startsWith('doctor:')).length;
    final clinicCount = favorites.where((k) => k.startsWith('clinic:')).length;
    final branchCount = favorites.where((k) => k.startsWith('pharmacy_branch:')).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Избранное', style: AppTextStyles.headingMedium),
        centerTitle: false,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 2.5,
          labelStyle: AppTextStyles.labelBold,
          unselectedLabelStyle: AppTextStyles.labelBold,
          tabs: [
            Tab(text: 'Врачи${doctorCount > 0 ? ' ($doctorCount)' : ''}'),
            Tab(text: 'Клиники${clinicCount > 0 ? ' ($clinicCount)' : ''}'),
            Tab(text: 'Аптеки${branchCount > 0 ? ' ($branchCount)' : ''}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _DoctorsTab(),
          _ClinicsTab(),
          _PharmaciesTab(),
        ],
      ),
    );
  }
}

// ─── Врачи ─────────────────────────────────────────────────────────────────

class _DoctorsTab extends ConsumerWidget {
  const _DoctorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final ids = favorites
        .where((k) => k.startsWith('doctor:'))
        .map((k) => int.parse(k.split(':')[1]))
        .toList();

    if (ids.isEmpty) {
      return _EmptyState(
        icon: PhosphorIconsRegular.stethoscope,
        title: 'Нет избранных врачей',
        subtitle: 'Нажмите ♡ на карточке врача чтобы добавить в избранное',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: ids.length,
      itemBuilder: (_, i) => _FavoriteDoctorTile(doctorId: ids[i]),
    );
  }
}

class _FavoriteDoctorTile extends ConsumerWidget {
  final int doctorId;
  const _FavoriteDoctorTile({required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(doctorByIdProvider(doctorId));
    final isFav = ref.watch(favoritesProvider).contains('doctor:$doctorId');

    return async.when(
      loading: () => _Shimmer(),
      error: (e, _) => const SizedBox.shrink(),
      data: (doctor) => DoctorCard(
        doctor: doctor,
        isFavorite: isFav,
        onFavoriteToggle: () =>
            ref.read(favoritesProvider.notifier).toggle('doctor', doctorId),
        onTap: () => context.push('/main/doctors/$doctorId'),
      ),
    );
  }
}

// ─── Клиники ───────────────────────────────────────────────────────────────

class _ClinicsTab extends ConsumerWidget {
  const _ClinicsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final ids = favorites
        .where((k) => k.startsWith('clinic:'))
        .map((k) => int.parse(k.split(':')[1]))
        .toList();

    if (ids.isEmpty) {
      return _EmptyState(
        icon: PhosphorIconsRegular.hospital,
        title: 'Нет избранных клиник',
        subtitle: 'Нажмите ♡ на карточке клиники чтобы добавить в избранное',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: ids.length,
      itemBuilder: (_, i) => _FavoriteClinicTile(clinicId: ids[i]),
    );
  }
}

class _FavoriteClinicTile extends ConsumerWidget {
  final int clinicId;
  const _FavoriteClinicTile({required this.clinicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clinicByIdProvider(clinicId));
    final isFav = ref.watch(favoritesProvider).contains('clinic:$clinicId');

    return async.when(
      loading: () => _Shimmer(),
      error: (e, _) => const SizedBox.shrink(),
      data: (clinic) {
        final logoUrl = clinic.logoUrl != null
            ? '${AppConstants.baseUrl}${clinic.logoUrl}'
            : null;
        return _FavoriteCard(
          imageUrl: logoUrl,
          title: clinic.name,
          subtitle: clinic.category ?? '',
          trailing: clinic.address ?? '',
          rating: clinic.rating,
          isFavorite: isFav,
          onFavoriteTap: () =>
              ref.read(favoritesProvider.notifier).toggle('clinic', clinicId),
          onTap: () => context.push('/main/clinics/$clinicId'),
        );
      },
    );
  }
}

// ─── Аптеки ────────────────────────────────────────────────────────────────

class _PharmaciesTab extends ConsumerWidget {
  const _PharmaciesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final ids = favorites
        .where((k) => k.startsWith('pharmacy_branch:'))
        .map((k) => int.parse(k.split(':')[1]))
        .toList();

    if (ids.isEmpty) {
      return _EmptyState(
        icon: PhosphorIconsRegular.pill,
        title: 'Нет избранных аптек',
        subtitle: 'Нажмите ♡ на карточке аптеки чтобы добавить в избранное',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: ids.length,
      itemBuilder: (_, i) => _FavoritePharmacyTile(branchId: ids[i]),
    );
  }
}

class _FavoritePharmacyTile extends ConsumerWidget {
  final int branchId;
  const _FavoritePharmacyTile({required this.branchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(branchByIdProvider(branchId));
    final isFav =
        ref.watch(favoritesProvider).contains('pharmacy_branch:$branchId');

    return async.when(
      loading: () => _Shimmer(),
      error: (e, _) => const SizedBox.shrink(),
      data: (branch) {
        final logoUrl = branch.companyLogoUrl != null
            ? '${AppConstants.baseUrl}${branch.companyLogoUrl}'
            : null;
        return _FavoriteCard(
          imageUrl: logoUrl,
          title: branch.companyName ?? 'Аптека',
          subtitle: branch.address ?? '',
          trailing: branch.workingHours ?? '',
          rating: branch.rating,
          isFavorite: isFav,
          onFavoriteTap: () => ref
              .read(favoritesProvider.notifier)
              .toggle('pharmacy_branch', branchId),
          onTap: () => context.push('/main/pharmacies/branch/$branchId'),
        );
      },
    );
  }
}

// ─── Общая карточка для клиник и аптек ────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String subtitle;
  final String trailing;
  final double rating;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.rating,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            // Лого
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.backgroundChip,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (context, e, _) => const Icon(
                        Icons.local_hospital_outlined,
                        color: AppColors.primaryBlue,
                      ))
                  : const Icon(Icons.local_hospital_outlined,
                      color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            // Текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.labelBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (trailing.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(trailing,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Кнопка избранного
            GestureDetector(
              onTap: onFavoriteTap,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isFavorite
                      ? PhosphorIconsFill.heart
                      : PhosphorIconsRegular.heart,
                  color:
                      isFavorite ? AppColors.error : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ───────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 84,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─── Пустое состояние ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.backgroundChip,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
