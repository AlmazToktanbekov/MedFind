import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/clinic_model.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../providers/clinics_provider.dart';
import '../../../clinics/data/clinics_repository.dart';
import '../../../doctors/providers/reviews_provider.dart';
import '../../../../shared/widgets/review_card.dart';
import '../../../../core/analytics/analytics_tracker.dart';

class ClinicDetailScreen extends ConsumerWidget {
  final String clinicId;
  const ClinicDetailScreen({super.key, required this.clinicId});

  Future<void> _call(int clinicIdInt, String phone) async {
    AnalyticsTracker().clickCall('clinic', clinicIdInt);
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(int clinicIdInt, String number) {
    AnalyticsTracker().clickWhatsapp('clinic', clinicIdInt);
    return _openUrl('https://wa.me/$number');
  }

  Future<void> _openTelegram(int clinicIdInt, String username) {
    AnalyticsTracker().clickTelegram('clinic', clinicIdInt);
    final handle = username.startsWith('@') ? username.substring(1) : username;
    return _openUrl('https://t.me/$handle');
  }

  Future<void> _openMaps(int clinicIdInt, String mapUrl) {
    AnalyticsTracker().clickRoute('clinic', clinicIdInt);
    return _openUrl(mapUrl);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(clinicId) ?? 0;
    if (id != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AnalyticsTracker().viewClinic(id);
      });
    }
    final clinicAsync = ref.watch(clinicByIdProvider(id));
    final isFavorite = ref.watch(favoritesProvider).contains('clinic:$id');

    return clinicAsync.when(
      loading: () => const _ClinicDetailShimmer(),
      error: (_, _) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primaryDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Не удалось загрузить клинику',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () => ref.refresh(clinicByIdProvider(id)),
                child: Text('Повторить', style: AppTextStyles.labelBold),
              ),
            ],
          ),
        ),
      ),
      data: (clinic) => _ClinicTabScaffold(
        clinic: clinic,
        isFavorite: isFavorite,
        onFavoriteToggle: () =>
            ref.read(favoritesProvider.notifier).toggle('clinic', id),
        onCall: clinic.phone != null ? () => _call(id, clinic.phone!) : null,
        onMaps: clinic.mapUrl != null ? () => _openMaps(id, clinic.mapUrl!) : null,
        onWhatsApp: clinic.whatsapp != null
            ? () => _openWhatsApp(id, clinic.whatsapp!)
            : null,
        onTelegram: clinic.telegram != null
            ? () => _openTelegram(id, clinic.telegram!)
            : null,
        onInstagram: clinic.instagram != null
            ? () => _openUrl(
                'https://instagram.com/${clinic.instagram!.replaceAll('@', '')}',
              )
            : null,
        onEmail: clinic.email != null
            ? () => _openUrl('mailto:${clinic.email}')
            : null,
        onWebsite: clinic.website != null
            ? () => _openUrl(
                clinic.website!.startsWith('http')
                    ? clinic.website!
                    : 'https://${clinic.website}',
              )
            : null,
      ),
    );
  }
}

// ─── Main tabbed scaffold ─────────────────────────────────────────────────

class _ClinicTabScaffold extends StatelessWidget {
  final ClinicModel clinic;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onCall;
  final VoidCallback? onMaps;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onTelegram;
  final VoidCallback? onInstagram;
  final VoidCallback? onEmail;
  final VoidCallback? onWebsite;

  const _ClinicTabScaffold({
    required this.clinic,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onCall,
    this.onMaps,
    this.onWhatsApp,
    this.onTelegram,
    this.onInstagram,
    this.onEmail,
    this.onWebsite,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundApp,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            _buildHero(context),
            _buildInfoHeader(),
            SliverPersistentHeader(pinned: true, delegate: _StickyTabBar()),
          ],
          body: TabBarView(
            children: [
              _AboutTab(
                clinic: clinic,
                onWhatsApp: onWhatsApp,
                onTelegram: onTelegram,
                onInstagram: onInstagram,
                onEmail: onEmail,
                onWebsite: onWebsite,
              ),
              _DoctorsTab(clinicId: clinic.id),
              _ReviewsTab(clinicId: clinic.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 155,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (onFavoriteToggle != null)
          IconButton(
            icon: Icon(
              isFavorite
                  ? PhosphorIconsFill.heart
                  : PhosphorIconsRegular.heart,
              color: isFavorite ? const Color(0xFFE53935) : Colors.white,
            ),
            onPressed: onFavoriteToggle,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 5, right: 5, bottom: 18),
        title: Text(
          clinic.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headingMedium.copyWith(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(
                color: Colors.black87,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              Shadow(
                color: Colors.black54,
                blurRadius: 14,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroBackground(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ],
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _buildHeroBackground() {
    final bgPhoto = clinic.photos.isNotEmpty
        ? clinic.photos.first.url
        : clinic.photoUrl;

    if (bgPhoto != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: bgPhoto,
            fit: BoxFit.cover,
            placeholder: (_, _) => _gradientBg(),
            errorWidget: (_, _, _) => _gradientBg(),
          ),
          Container(color: Colors.black.withValues(alpha: 0.4)),
        ],
      );
    }
    return _gradientBg();
  }

  Widget _gradientBg() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
    );
  }

  Widget _buildInfoHeader() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating (indented to leave space for logo)
                  Padding(
                    padding: const EdgeInsets.only(left: 74),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinic.name,
                          style: AppTextStyles.headingMedium.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RatingStars(
                          rating: clinic.rating,
                          reviewCount: clinic.reviewsCount,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Specializations — horizontal scroll
                  if (clinic.category != null) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: clinic.category!
                            .split(', ')
                            .map(
                              (cat) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cat,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Address
                  if (clinic.address != null) ...[
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.mapPin,
                          color: AppColors.textSecondary,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            clinic.address!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ] else
                    const SizedBox(height: 8),

                  // Action buttons
                  if (onCall != null || onMaps != null) ...[
                    Row(
                      children: [
                        if (onCall != null)
                          Expanded(
                            child: GradientButton(
                              text: 'Позвонить',
                              onPressed: onCall,
                            ),
                          ),
                        if (onCall != null && onMaps != null)
                          const SizedBox(width: 10),
                        if (onMaps != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onMaps,
                              icon: const Icon(
                                PhosphorIconsRegular.mapPin,
                                size: 18,
                              ),
                              label: const Text('Маршрут'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(
                                  color: AppColors.primaryBlue,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else
                    const SizedBox(height: 16),
                ],
              ),
            ),

            // Logo container overlapping the hero
            Positioned(
              top: 10,
              left: 18,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: clinic.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: clinic.logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _logoInitial(clinic.name),
                          errorWidget: (_, _, _) => _logoInitial(clinic.name),
                        )
                      : _logoInitial(clinic.name),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _logoInitial(String name) {
    return Container(
      color: AppColors.primaryBlue.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'М',
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Sticky tab bar ───────────────────────────────────────────────────────

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  static const double _height = 52;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: _height,
        child: Column(
          children: [
            Expanded(
              child: TabBar(
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryBlue,
                indicatorWeight: 2.5,
                labelStyle: AppTextStyles.labelBold.copyWith(fontSize: 14),
                unselectedLabelStyle: AppTextStyles.bodySmall,
                tabs: const [
                  Tab(text: 'О клинике'),
                  Tab(text: 'Врачи'),
                  Tab(text: 'Отзывы'),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF8)),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBar oldDelegate) => false;
}
// ─── Tab 1: О клинике ─────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final ClinicModel clinic;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onTelegram;
  final VoidCallback? onInstagram;
  final VoidCallback? onEmail;
  final VoidCallback? onWebsite;

  const _AboutTab({
    required this.clinic,
    this.onWhatsApp,
    this.onTelegram,
    this.onInstagram,
    this.onEmail,
    this.onWebsite,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Working hours — compact horizontal scroll
        if (clinic.workingHours != null && clinic.workingHours!.isNotEmpty) ...[
          Text('График работы', style: AppTextStyles.headingMedium),
          const SizedBox(height: 10),
          _CompactSchedule(raw: clinic.workingHours!),
          const SizedBox(height: 20),
        ],

        // Social / contact chips
        if (onWhatsApp != null ||
            onTelegram != null ||
            onInstagram != null ||
            onEmail != null ||
            onWebsite != null) ...[
          Text('Контакты', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onWhatsApp != null)
                _ContactChip(
                  icon: PhosphorIconsFill.whatsappLogo,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: onWhatsApp!,
                ),
              if (onTelegram != null)
                _ContactChip(
                  icon: PhosphorIconsFill.telegramLogo,
                  label: 'Telegram',
                  color: const Color(0xFF0088CC),
                  onTap: onTelegram!,
                ),
              if (onInstagram != null)
                _ContactChip(
                  icon: PhosphorIconsFill.instagramLogo,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: onInstagram!,
                ),
              if (onEmail != null)
                _ContactChip(
                  icon: PhosphorIconsFill.envelope,
                  label: 'Email',
                  color: AppColors.accentBlue,
                  onTap: onEmail!,
                ),
              if (onWebsite != null)
                _ContactChip(
                  icon: PhosphorIconsFill.globe,
                  label: 'Сайт',
                  color: AppColors.primaryBlue,
                  onTap: onWebsite!,
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Photo gallery
        if (clinic.photos.isNotEmpty) ...[
          Text('Фотографии', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: clinic.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: clinic.photos[i].url,
                  width: 160,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade200,
                    highlightColor: Colors.grey.shade100,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.backgroundChip,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        ], // Description
        if (clinic.description != null && clinic.description!.isNotEmpty) ...[
          Text('О клинике', style: AppTextStyles.headingMedium),
          const SizedBox(height: 8),
          Text(clinic.description!, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

// ─── Compact schedule (horizontal scroll) ────────────────────────────────

class _CompactSchedule extends StatelessWidget {
  final String raw;
  const _CompactSchedule({required this.raw});

  @override
  Widget build(BuildContext context) {
    final lines = raw
        .split(RegExp(r',\s*(?=[А-Я][а-я]? )'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (lines.length <= 1) {
      return Text(raw, style: AppTextStyles.bodyLarge);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: lines.map((line) {
          final parts = line.split(' ');
          final day = parts.isNotEmpty ? parts.first : '';
          final time = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day,
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tab 2: Врачи ─────────────────────────────────────────────────────────

class _DoctorsTab extends StatefulWidget {
  final int clinicId;
  const _DoctorsTab({required this.clinicId});

  @override
  State<_DoctorsTab> createState() => _DoctorsTabState();
}

class _DoctorsTabState extends State<_DoctorsTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = ClinicsRepository().getClinicDoctors(widget.clinicId);
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static const List<Color> _avatarColors = [
    Color(0xFF7C3AED),
    Color(0xFF0D9488),
    Color(0xFF0891B2),
    Color(0xFF059669),
    Color(0xFFDC2626),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFF1D4ED8),
  ];

  Color _avatarColor(int index) => _avatarColors[index % _avatarColors.length];

  String _formatPrice(Map<String, dynamic> d) {
    final online = (d['online_price'] as num?)?.toDouble();
    final offline = (d['offline_price'] as num?)?.toDouble();
    final prices = <double>[?online, ?offline];
    if (prices.isEmpty) return '';
    final min = prices.reduce((a, b) => a < b ? a : b);
    return 'от ${min.toInt()} ₸';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final doctors = snap.data ?? [];
        if (doctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  PhosphorIconsRegular.userCircle,
                  size: 56,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Нет подтверждённых врачей',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final Map<String, List<Map<String, dynamic>>> groups = {};
        for (final d in doctors) {
          final spec = (d['specialization_ru'] as String?)?.trim() ?? 'Другое';
          groups.putIfAbsent(spec, () => []).add(d);
        }

        int globalIndex = 0;
        final items = <Widget>[];
        for (final entry in groups.entries) {
          final spec = entry.key;
          final list = entry.value;
          final count = list.length;
          items.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    spec,
                    style: AppTextStyles.labelBold.copyWith(fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count ${_doctorWord(count)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
          for (final d in list) {
            final idx = globalIndex++;
            items.add(
              _DoctorCard(
                doctor: d,
                avatarColor: _avatarColor(idx),
                initials: _initials(d['full_name_ru'] as String? ?? ''),
                priceLabel: _formatPrice(d),
              ),
            );
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: items,
        );
      },
    );
  }

  String _doctorWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'врач';
    if (n % 10 >= 2 && n % 10 <= 4 && !(n % 100 >= 12 && n % 100 <= 14)) {
      return 'врача';
    }
    return 'врачей';
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final Color avatarColor;
  final String initials;
  final String priceLabel;

  const _DoctorCard({
    required this.doctor,
    required this.avatarColor,
    required this.initials,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final id = doctor['id'] as int;
    final name = doctor['full_name_ru'] as String? ?? '—';
    final photo = doctor['photo_url'] as String?;
    final experience = doctor['experience_years'] as int?;
    final rating = (doctor['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewsCount = doctor['reviews_count'] as int? ?? 0;
    final hasOnline = doctor['has_online'] as bool? ?? false;
    final hasOffline = doctor['has_offline'] as bool? ?? true;

    return GestureDetector(
      onTap: () => context.push('/main/doctors/$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: photo == null ? avatarColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: photo != null
                  ? CachedNetworkImage(
                      imageUrl: photo,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
                    name,
                    style: AppTextStyles.labelBold.copyWith(fontSize: 14),
                  ),
                  if (experience != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$experience ${_expWord(experience)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFC107),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '($reviewsCount)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (priceLabel.isNotEmpty)
                  Text(
                    priceLabel,
                    style: AppTextStyles.labelBold.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasOffline) ...[
                      _FormatBadge(label: 'Очно', color: AppColors.success),
                      const SizedBox(width: 4),
                    ],
                    if (hasOnline)
                      _FormatBadge(
                        label: 'Онлайн',
                        color: AppColors.primaryBlue,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _expWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'год стажа';
    if (n % 10 >= 2 && n % 10 <= 4 && !(n % 100 >= 12 && n % 100 <= 14)) {
      return 'года стажа';
    }
    return 'лет стажа';
  }
}

class _FormatBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _FormatBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Tab 3: Отзывы ────────────────────────────────────────────────────────

class _ReviewsTab extends ConsumerStatefulWidget {
  final int clinicId;
  const _ReviewsTab({required this.clinicId});

  @override
  ConsumerState<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<_ReviewsTab>
    with AutomaticKeepAliveClientMixin {
  final _reviewCtrl = TextEditingController();
  double _rating = 5;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _reviewCtrl.text.trim();
    if (text.isEmpty) return;
    final ok = await ref
        .read(clinicReviewsProvider(widget.clinicId).notifier)
        .submit(_rating, text);
    if (ok && mounted) {
      _reviewCtrl.clear();
      setState(() => _rating = 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(clinicReviewsProvider(widget.clinicId));

    if (state.submitError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.submitError!),
            backgroundColor: AppColors.error,
          ),
        );
        ref
            .read(clinicReviewsProvider(widget.clinicId).notifier)
            .clearSubmitError();
      });
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: () => _showReviewSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppColors.btnGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  PhosphorIconsRegular.pencilSimple,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Написать отзыв',
                  style: AppTextStyles.labelBold.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (state.error != null)
          TextButton(
            onPressed: () => ref
                .read(clinicReviewsProvider(widget.clinicId).notifier)
                .load(),
            child: Text('Повторить', style: AppTextStyles.labelBold),
          )
        else if (state.reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  const Icon(
                    PhosphorIconsRegular.star,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Пока нет отзывов',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...state.reviews.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ReviewCard(
              review: r,
              onUpdate: ref.read(clinicReviewsProvider(widget.clinicId).notifier).update,
              onDelete: ref.read(clinicReviewsProvider(widget.clinicId).notifier).delete,
            ),
          )),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Написать отзыв', style: AppTextStyles.headingMedium),
                const SizedBox(height: 16),
                Text(
                  'Оценка',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final star = (i + 1).toDouble();
                    return GestureDetector(
                      onTap: () => setSheetState(() => _rating = star),
                      child: Icon(
                        _rating >= star
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.warning,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  'Комментарий',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reviewCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Расскажите о своём опыте...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundApp,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.btnGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _submit();
                      },
                      child: Text(
                        'Отправить',
                        style: AppTextStyles.labelBold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicDetailShimmer extends StatelessWidget {
  const _ClinicDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Container(height: 155, color: Colors.white),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(
                  4,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
