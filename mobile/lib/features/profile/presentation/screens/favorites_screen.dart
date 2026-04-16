import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../../../shared/widgets/doctor_card.dart';
import '../../../../features/doctors/providers/doctors_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final doctorIds = favorites
        .where((k) => k.startsWith('doctor:'))
        .map((k) => int.parse(k.split(':')[1]))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Избранное', style: AppTextStyles.headingMedium),
        centerTitle: false,
      ),
      body: doctorIds.isEmpty
          ? _EmptyFavorites()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: doctorIds.length,
              itemBuilder: (_, index) {
                return _FavoriteDoctorTile(
                  doctorId: doctorIds[index],
                );
              },
            ),
    );
  }
}

// ─── Карточка избранного врача (загружает данные по id) ────────────────────

class _FavoriteDoctorTile extends ConsumerWidget {
  final int doctorId;

  const _FavoriteDoctorTile({required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorByIdProvider(doctorId));
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains('doctor:$doctorId');

    return doctorAsync.when(
      loading: () => _shimmerCard(),
      error: (_, __) => const SizedBox.shrink(),
      data: (doctor) => DoctorCard(
        doctor: doctor,
        isFavorite: isFav,
        onFavoriteToggle: () =>
            ref.read(favoritesProvider.notifier).toggle('doctor', doctorId),
        onTap: () => context.push('/main/doctors/$doctorId'),
      ),
    );
  }

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 90,
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

class _EmptyFavorites extends StatelessWidget {
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
              child: const Icon(
                PhosphorIconsRegular.heart,
                size: 36,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text('Нет избранных врачей', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Нажмите ♡ на карточке врача чтобы добавить в избранное',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
