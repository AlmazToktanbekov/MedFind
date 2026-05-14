import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../../features/notifications/providers/notifications_provider.dart';

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
    final unreadCount = ref.watch(notificationsProvider).unreadCount;
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(profile, unreadCount)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: CustomSearchBar(onTap: () => context.push('/main/search')),
            ),
          ),
          SliverToBoxAdapter(child: _buildQuickServices(context)),
          SliverToBoxAdapter(child: _buildAiChatBanner(context)),
          SliverToBoxAdapter(child: _buildSymptomsHero(context, ref)),
          SliverToBoxAdapter(child: _buildSpecializationsSection(context)),
          SliverToBoxAdapter(child: _buildDoctorsSection(context, ref)),
          SliverToBoxAdapter(child: _buildClinicsSection(context, ref)),
          SliverToBoxAdapter(child: _buildPharmaciesSection(context, ref)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(ProfileState profile, int unreadCount) {
    final role = profile.role;
    final isProvider = role == 'doctor' || role == 'clinic' || role == 'pharmacy' || role == 'admin';

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
            child: profile.photoUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profile.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, e) => Center(
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
                  )
                : Center(
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
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  profile.isLoading ? '...' : profile.displayName,
                  style: AppTextStyles.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!profile.isLoading && role != null)
                  const SizedBox(height: 3),
                if (!profile.isLoading && role != null)
                  _RoleBadge(role: role),
              ],
            ),
          ),
          if (isProvider)
            _BellButton(unreadCount: unreadCount),
        ],
      ),
    );
  }

  Widget _buildQuickServices(BuildContext context) {
    final items = [
      (
        PhosphorIconsFill.stethoscope,
        'Врачи',
        AppColors.primaryBlue,
        '/main/doctors',
      ),
      (
        PhosphorIconsFill.hospital,
        'Клиники',
        AppColors.accentBlue,
        '/main/clinics',
      ),
      (PhosphorIconsFill.pill, 'Аптеки', AppColors.warning, '/main/pharmacies'),
      (
        PhosphorIconsFill.magnifyingGlass,
        'Поиск',
        AppColors.success,
        '/main/search',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: GestureDetector(
                  onTap: () => context.push(item.$4),
                  child: Container(
                    margin: EdgeInsets.only(right: item == items.last ? 0 : 10),
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
                          child: Icon(item.$1, color: item.$3, size: 22),
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
              ),
            )
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
                  Text('ИИ-Помощник', style: AppTextStyles.labelBold),
                  const SizedBox(height: 3),
                  Text(
                    'Опишите симптомы — ИИ подскажет\nк какому врачу обратиться',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

  Widget _buildSymptomsHero(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(symptomsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Симптомы',
          onTapAll: () => context.push('/main/symptoms'),
        ),
        symptomsAsync.when(
          loading: () => const _HorizontalShimmer(height: 116, width: 100),
          error: (e, _) => const SizedBox.shrink(),
          data: (symptoms) => SizedBox(
            height: 116,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: symptoms.take(8).length,
              itemBuilder: (_, index) {
                final s = symptoms[index];
                return GestureDetector(
                  onTap: () => context.push(
                    '/main/doctors/by-symptom/${s.id}',
                    extra: s.nameRu,
                  ),
                  child: _SymptomCard(label: s.nameRu, index: index),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSpecializationsSection(BuildContext context) {
    final specs = AppConstants.specializations.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Специализации',
          onTapAll: () => context.push('/main/specializations'),
        ),
        SizedBox(
          height: 116,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: specs.length,
            itemBuilder: (_, index) => GestureDetector(
              onTap: () => context.push(
                '/main/doctors/by-specialization',
                extra: specs[index],
              ),
              child: _SpecCard(label: specs[index], index: index),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDoctorsSection(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsProvider);
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: d.photoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: AppConstants.fixUrl(d.photoUrl!),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(
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
                                )
                              : Container(
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
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
                                style: AppTextStyles.labelBold.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB300),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    d.rating.toStringAsFixed(1),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (d.offlinePrice != null)
                                    Text(
                                      '${d.offlinePrice!.toInt()} сом',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
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
          loading: () => const _HorizontalShimmer(height: 96, width: 220),
          error: (e, st) => const SizedBox.shrink(),
          data: (clinics) => SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: clinics.take(6).length,
              itemBuilder: (_, index) {
                final c = clinics[index];
                return GestureDetector(
                  onTap: () => context.push('/main/clinics/${c.id}'),
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        // логотип
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.accentBlue.withValues(alpha: 0.08),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: c.logoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: AppConstants.fixUrl(c.logoUrl!),
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        const _ClinicLogoPlaceholder(),
                                  )
                                : const _ClinicLogoPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // информация
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.name,
                                style: AppTextStyles.labelBold.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (c.category != null) ...[
                                const SizedBox(height: 3),
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
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB300),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    c.rating.toStringAsFixed(1),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
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

  Widget _buildPharmaciesSection(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Аптеки',
          onTapAll: () => context.push('/main/pharmacies'),
        ),
        branchesAsync.when(
          loading: () => const _VerticalShimmer(count: 3),
          error: (e, st) => const SizedBox.shrink(),
          data: (branches) => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: branches.take(3).length,
            itemBuilder: (_, index) => GestureDetector(
              onTap: () =>
                  context.push('/main/pharmacies/branch/${branches[index].id}'),
              child: PharmacyBranchCard(branch: branches[index]),
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
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.primaryBlue,
                  ),
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

// ─── Symptom card ─────────────────────────────────────────────────────────

const _symptomEmojis = ['❤️', '🛡️', '🌸', '💑', '🦴', '💊', '🔙', '🩸'];
const _symptomAccents = [
  Color(0xFFE53935),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFFD81B60),
  Color(0xFF1565C0),
  Color(0xFFFF8C42),
  Color(0xFF00897B),
  Color(0xFFFFB300),
];
const _symptomBgs = [
  Color(0xFFFFEBEE),
  Color(0xFFE8F5E9),
  Color(0xFFF3E5F5),
  Color(0xFFFCE4EC),
  Color(0xFFE3F0FF),
  Color(0xFFFFF3E0),
  Color(0xFFE0F2F1),
  Color(0xFFFFF8E1),
];

class _SymptomCard extends StatelessWidget {
  final String label;
  final int index;
  const _SymptomCard({required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    final accent = _symptomAccents[index % _symptomAccents.length];
    final bg = _symptomBgs[index % _symptomBgs.length];
    final emoji = _symptomEmojis[index % _symptomEmojis.length];
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Spec card ─────────────────────────────────────────────────────────────

const _specEmojis = ['🩺', '❤️', '🤰', '🫁', '👂', '🧬', '💧', '🥗'];

const _specAccents = [
  Color(0xFF1565C0),
  Color(0xFFE53935),
  Color(0xFF8E24AA),
  Color(0xFF00897B),
  Color(0xFFFF8C42),
  Color(0xFF5E35B1),
  Color(0xFF039BE5),
  Color(0xFF43A047),
];

const _specBgs = [
  Color(0xFFE3F0FF),
  Color(0xFFFFEBEE),
  Color(0xFFF3E5F5),
  Color(0xFFE0F2F1),
  Color(0xFFFFF3E0),
  Color(0xFFEDE7F6),
  Color(0xFFE1F5FE),
  Color(0xFFE8F5E9),
];

class _SpecCard extends StatelessWidget {
  final String label;
  final int index;
  const _SpecCard({required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    final accent = _specAccents[index % _specAccents.length];
    final bg = _specBgs[index % _specBgs.length];
    final emoji = _specEmojis[index % _specEmojis.length];
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Clinic logo placeholder ───────────────────────────────────────────────

class _ClinicLogoPlaceholder extends StatelessWidget {
  const _ClinicLogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        PhosphorIconsFill.hospital,
        color: AppColors.accentBlue,
        size: 26,
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label, Color color) = switch (role) {
      'doctor' => (PhosphorIconsFill.stethoscope, 'Врач', AppColors.primaryBlue),
      'clinic' => (PhosphorIconsFill.hospital, 'Клиника', AppColors.accentBlue),
      'pharmacy' => (PhosphorIconsFill.pill, 'Аптека', AppColors.warning),
      'admin' => (PhosphorIconsFill.shieldCheck, 'Админ', const Color(0xFF6B21A8)),
      _ => (PhosphorIconsFill.user, 'Пациент', AppColors.textSecondary),
    };

    if (role == 'patient') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final int unreadCount;

  const _BellButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/main/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
