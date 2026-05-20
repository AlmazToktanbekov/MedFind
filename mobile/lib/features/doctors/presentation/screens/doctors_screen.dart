import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/filter_chip_widget.dart';
import '../../../../shared/widgets/doctor_card.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../providers/doctors_provider.dart';

class DoctorsScreen extends ConsumerWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(doctorFilterProvider);
    final query = ref.watch(doctorSearchQueryProvider).trim().toLowerCase();
    final doctorsAsync = ref.watch(doctorsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Врачи', style: AppTextStyles.headingMedium),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: CustomSearchBar(
              onChanged: (v) =>
                  ref.read(doctorSearchQueryProvider.notifier).state = v,
            ),
          ),
          _ConsultationFilterBar(currentFilter: filter),
          const SizedBox(height: 8),
          const _SpecializationFilterBar(),
          const SizedBox(height: 12),
          Expanded(
            child: doctorsAsync.when(
              loading: () => const _DoctorsShimmer(),
              error: (e, _) => _ErrorView(
                onRetry: () => ref.refresh(doctorsProvider),
              ),
              data: (allDoctors) {
                final doctors = query.isEmpty
                    ? allDoctors
                    : allDoctors.where((d) {
                        final name = d.fullName.toLowerCase();
                        final spec = d.specialization.toLowerCase();
                        return name.contains(query) || spec.contains(query);
                      }).toList();
                if (doctors.isEmpty) {
                  return const _EmptyView();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doctors.length,
                  itemBuilder: (_, index) {
                    final doctor = doctors[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + index * 60),
                      curve: Curves.easeOut,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      ),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isFav = ref
                              .watch(favoritesProvider)
                              .contains('doctor:${doctor.id}');
                          return DoctorCard(
                            doctor: doctor,
                            isFavorite: isFav,
                            onFavoriteToggle: () => ref
                                .read(favoritesProvider.notifier)
                                .toggle('doctor', doctor.id),
                            onTap: () =>
                                context.push('/main/doctors/${doctor.id}'),
                          );
                        },
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

// ─── Consultation filter (Все / Онлайн) ───────────────────────────────────

class _ConsultationFilterBar extends ConsumerWidget {
  final DoctorFilter currentFilter;
  const _ConsultationFilterBar({required this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const filters = [
      (DoctorFilter.all, 'Все'),
      (DoctorFilter.online, 'Онлайн'),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final (filterVal, label) = f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChipWidget(
              label: label,
              isActive: currentFilter == filterVal,
              onTap: () =>
                  ref.read(doctorFilterProvider.notifier).state = filterVal,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Specialization filter chips ──────────────────────────────────────────

class _SpecializationFilterBar extends ConsumerWidget {
  const _SpecializationFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(doctorSpecializationProvider);

    final specs = ['Все', ...AppConstants.specializations];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: specs.map((s) {
          final isAll = s == 'Все';
          final isActive = isAll ? selected == null : selected == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChipWidget(
              label: s,
              isActive: isActive,
              onTap: () => ref.read(doctorSpecializationProvider.notifier).state =
                  isAll ? null : s,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Shimmer loading ───────────────────────────────────────────────────────

class _DoctorsShimmer extends StatelessWidget {
  const _DoctorsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, _) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ─── Error view ────────────────────────────────────────────────────────────

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
          const SizedBox(height: 16),
          Text('Не удалось загрузить врачей',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onRetry,
            child: Text('Повторить', style: AppTextStyles.labelBold),
          ),
        ],
      ),
    );
  }
}

// ─── Empty view ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('Врачи не найдены',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
