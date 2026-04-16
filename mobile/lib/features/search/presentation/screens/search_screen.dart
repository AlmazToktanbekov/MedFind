import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/doctor_card.dart';
import '../../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHistoryTap(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: query.length);
    ref.read(searchProvider.notifier).searchFromHistory(query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Поиск', style: AppTextStyles.headingLarge),
                  const SizedBox(height: 12),
                  CustomSearchBar(
                    controller: _controller,
                    hint: 'Врач, клиника, симптом...',
                    onChanged: (q) =>
                        ref.read(searchProvider.notifier).onQueryChanged(q),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────
            Expanded(
              child: switch (state.status) {
                SearchStatus.idle => _HistoryView(
                    history: state.history,
                    onTap: _onHistoryTap,
                    onClear: () =>
                        ref.read(searchProvider.notifier).clearHistory(),
                  ),
                SearchStatus.loading => const _SearchShimmer(),
                SearchStatus.loaded when !state.hasResults =>
                  const _EmptyResultsView(),
                SearchStatus.loaded => _ResultsView(state: state),
                SearchStatus.error => const _ErrorView(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── История поиска ────────────────────────────────────────────────────────

class _HistoryView extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  const _HistoryView({
    required this.history,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Начните вводить запрос',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Недавние', style: AppTextStyles.headingMedium),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Очистить',
                style: AppTextStyles.labelBold
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: history
              .map(
                (q) => GestureDetector(
                  onTap: () => onTap(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsRegular.clockCounterClockwise,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(q, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─── Результаты поиска ─────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final SearchState state;

  const _ResultsView({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // Врачи
        if (state.doctors.isNotEmpty) ...[
          _SectionTitle(title: 'Врачи', count: state.doctors.length),
          ...state.doctors.map(
            (d) => DoctorCard(
              doctor: d,
              onTap: () => context.push('/main/doctors/${d.id}'),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Клиники
        if (state.clinics.isNotEmpty) ...[
          _SectionTitle(title: 'Клиники', count: state.clinics.length),
          ...state.clinics.map(
            (c) => _ClinicResultCard(
              clinic: c,
              onTap: () => context.push('/main/clinics/${c.id}'),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Аптеки
        if (state.pharmacies.isNotEmpty) ...[
          _SectionTitle(title: 'Аптеки', count: state.pharmacies.length),
          ...state.pharmacies.map(
            (p) => _PharmacyResultCard(
              pharmacy: p,
              onTap: () => context.push('/main/pharmacies'),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Заголовок секции ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.headingMedium),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.backgroundChip,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelBold.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Карточка клиники ──────────────────────────────────────────────────────

class _ClinicResultCard extends StatelessWidget {
  final dynamic clinic;
  final VoidCallback onTap;

  const _ClinicResultCard({required this.clinic, required this.onTap});

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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.backgroundChip,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                PhosphorIconsRegular.hospital,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinic.name as String,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (clinic.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      clinic.category as String,
                      style: AppTextStyles.labelBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (clinic.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      clinic.address as String,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFB300), size: 14),
                const SizedBox(width: 3),
                Text(
                  (clinic.rating as double).toStringAsFixed(1),
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Карточка аптеки ───────────────────────────────────────────────────────

class _PharmacyResultCard extends StatelessWidget {
  final dynamic pharmacy;
  final VoidCallback onTap;

  const _PharmacyResultCard({required this.pharmacy, required this.onTap});

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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.backgroundChip,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                PhosphorIconsRegular.pill,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name as String,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pharmacy.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      pharmacy.address as String,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (pharmacy.isOpen24h == true)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '24 ч',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer при загрузке ──────────────────────────────────────────────────

class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section headers + cards
            for (int s = 0; s < 3; s++) ...[
              Container(
                  height: 20, width: 100, color: Colors.white),
              const SizedBox(height: 10),
              for (int i = 0; i < 2; i++) ...[
                Container(
                  height: 76,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Пустые результаты ─────────────────────────────────────────────────────

class _EmptyResultsView extends StatelessWidget {
  const _EmptyResultsView();

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
              decoration: BoxDecoration(
                color: AppColors.backgroundChip,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsRegular.magnifyingGlass,
                size: 36,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ничего не найдено',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте другой запрос или проверьте написание',
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

// ─── Ошибка сети ───────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style:
                AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
