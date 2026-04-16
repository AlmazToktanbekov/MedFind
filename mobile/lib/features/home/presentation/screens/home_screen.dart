import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../features/pharmacies/presentation/screens/pharmacies_screen.dart';
import '../../../../features/doctors/providers/doctors_provider.dart';
import '../../../../features/clinics/providers/clinics_provider.dart';
import '../../../../features/pharmacies/providers/pharmacies_provider.dart';
import '../../../../features/profile/providers/profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(profile)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: CustomSearchBar(
                onTap: () => context.push('/main/search'),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildQuickServices(context)),
          SliverToBoxAdapter(child: _buildAiChatBanner(context)),
          SliverToBoxAdapter(child: _buildSymptomsHero(context)),
          SliverToBoxAdapter(child: _buildSpecializationsSection(context)),
          SliverToBoxAdapter(child: _buildDoctorsSection(context, ref)),
          SliverToBoxAdapter(child: _buildClinicsSection(context, ref)),
          SliverToBoxAdapter(child: _buildPharmaciesSection(context, ref)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(ProfileState profile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.btnGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  profile.isLoading ? '...' : profile.displayName,
                  style: AppTextStyles.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Icon(
              PhosphorIconsRegular.bell,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServices(BuildContext context) {
    final items = [
      (PhosphorIconsFill.stethoscope, 'Врачи', AppColors.primaryBlue,
          '/main/doctors'),
      (PhosphorIconsFill.hospital, 'Клиники', AppColors.accentBlue,
          '/main/clinics'),
      (PhosphorIconsFill.pill, 'Аптеки', AppColors.warning,
          '/main/pharmacies'),
      (PhosphorIconsFill.magnifyingGlass, 'Поиск', AppColors.success,
          '/main/search'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: items
            .map((item) => Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(item.$4),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: item == items.last ? 0 : 10),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.$3.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.$1,
                                color: item.$3, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.$2,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAiChatBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/main/ai-chat'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.btnGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                PhosphorIconsFill.robot,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ИИ-Симптом Чекер',
                    style: AppTextStyles.labelBold,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Опишите симптомы — ИИ подскажет\nк какому врачу обратиться',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundChip,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                PhosphorIconsRegular.arrowRight,
                color: AppColors.primaryBlue,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsHero(BuildContext context) {
    final symptoms = AppConstants.symptoms.take(8).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        PhosphorIconsFill.heartbeat,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Найти врача по симптому',
                      style: AppTextStyles.headingMedium
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: symptoms.length,
                  itemBuilder: (_, index) =>
                      _SymptomChip(label: symptoms[index]),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.push('/main/doctors'),
                  child: Row(
                    children: [
                      Text(
                        'Все симптомы',
                        style: AppTextStyles.labelBold
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(PhosphorIconsRegular.arrowRight,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationsSection(BuildContext context) {
    final specs = AppConstants.specializations.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Специализации',
          onTapAll: () => context.push('/main/doctors'),
        ),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: specs.length,
            itemBuilder: (_, index) => _SpecCard(
              label: specs[index],
              index: index,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDoctorsSection(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsProvider(DoctorFilter.all));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Врачи',
          onTapAll: () => context.push('/main/doctors'),
        ),
        doctorsAsync.when(
          loading: () => const _HorizontalShimmer(height: 136, width: 240),
          error: (e, st) => const SizedBox.shrink(),
          data: (doctors) => SizedBox(
            height: 136,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: doctors.take(6).length,
              itemBuilder: (_, index) {
                final d = doctors[index];
                return GestureDetector(
                  onTap: () => context.push('/main/doctors/${d.id}'),
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppColors.btnGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            PhosphorIconsFill.userCircle,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundChip,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  d.specialization,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 10,
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                d.fullName,
                                style: AppTextStyles.labelBold
                                    .copyWith(color: AppColors.textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFFFB300), size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    d.rating.toStringAsFixed(1),
                                    style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  if (d.offlinePrice != null)
                                    Text(
                                      '${d.offlinePrice!.toInt()} сом',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildClinicsSection(BuildContext context, WidgetRef ref) {
    final clinicsAsync = ref.watch(clinicsProvider(null));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Клиники',
          onTapAll: () => context.push('/main/clinics'),
        ),
        clinicsAsync.when(
          loading: () => const _HorizontalShimmer(height: 120, width: 190),
          error: (e, st) => const SizedBox.shrink(),
          data: (clinics) => SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: clinics.take(6).length,
              itemBuilder: (_, index) {
                final c = clinics[index];
                return GestureDetector(
                  onTap: () => context.push('/main/clinics/${c.id}'),
                  child: Container(
                    width: 190,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                PhosphorIconsFill.hospital,
                                color: AppColors.accentBlue,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFB300), size: 13),
                              const SizedBox(width: 2),
                              Text(c.rating.toStringAsFixed(1),
                                  style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          c.name,
                          style: AppTextStyles.labelBold
                              .copyWith(color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (c.category != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            c.category!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPharmaciesSection(BuildContext context, WidgetRef ref) {
    final pharmaciesAsync = ref.watch(pharmaciesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Аптеки',
          onTapAll: () => context.push('/main/pharmacies'),
        ),
        pharmaciesAsync.when(
          loading: () => const _VerticalShimmer(count: 3),
          error: (e, st) => const SizedBox.shrink(),
          data: (pharmacies) => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: pharmacies.take(3).length,
            itemBuilder: (_, index) => PharmacyCard(
              pharmacy: pharmacies[index],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTapAll;

  const _SectionHeader({required this.title, required this.onTapAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.headingMedium),
          GestureDetector(
            onTap: onTapAll,
            child: Row(
              children: [
                Text(
                  'Все',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 2),
                const Icon(
                  PhosphorIconsRegular.arrowRight,
                  color: AppColors.primaryBlue,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer ───────────────────────────────────────────────────────────────

class _HorizontalShimmer extends StatelessWidget {
  final double height;
  final double width;

  const _HorizontalShimmer({required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (context, index) => Container(
            width: width,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalShimmer extends StatelessWidget {
  final int count;
  const _VerticalShimmer({required this.count});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            count,
            (_) => Container(
              height: 76,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Symptom chip ──────────────────────────────────────────────────────────

class _SymptomChip extends StatelessWidget {
  final String label;
  const _SymptomChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Spec card ─────────────────────────────────────────────────────────────

const _specIcons = [
  PhosphorIconsRegular.stethoscope,
  PhosphorIconsRegular.tooth,
  PhosphorIconsRegular.eye,
  PhosphorIconsRegular.heartbeat,
  PhosphorIconsRegular.brain,
  PhosphorIconsRegular.bone,
  PhosphorIconsRegular.baby,
  PhosphorIconsRegular.syringe,
  PhosphorIconsRegular.firstAid,
  PhosphorIconsRegular.stethoscope,
];

const _specColors = [
  AppColors.primaryBlue,
  AppColors.accentBlue,
  AppColors.success,
  Color(0xFFE53935),
  Color(0xFF8E24AA),
  AppColors.warning,
  AppColors.primaryBlue,
  AppColors.success,
  AppColors.accentBlue,
  AppColors.warning,
];

class _SpecCard extends StatelessWidget {
  final String label;
  final int index;
  const _SpecCard({required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = _specColors[index % _specColors.length];
    final icon = _specIcons[index % _specIcons.length];
    return Container(
      width: 84,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
