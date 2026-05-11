import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../providers/pharmacies_provider.dart';
import '../../utils/pharmacy_hours.dart';
import 'pharmacies_screen.dart' show PharmacyBranchCard;

class PharmacyCompanyScreen extends ConsumerWidget {
  final String companyId;
  const PharmacyCompanyScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(companyId) ?? 0;
    final companyAsync = ref.watch(companyByIdProvider(id));

    return companyAsync.when(
      loading: () => const _CompanyShimmer(),
      error: (e, s) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primaryDark),
        body: const Center(child: Text('Не удалось загрузить')),
      ),
      data: (company) => _CompanyBody(company: company),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _CompanyBody extends StatefulWidget {
  final PharmacyCompanyModel company;
  const _CompanyBody({required this.company});

  @override
  State<_CompanyBody> createState() => _CompanyBodyState();
}

class _CompanyBodyState extends State<_CompanyBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  static const _kHeaderHeight = 340.0;
  static const _kOverlap = 20.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.animation?.addListener(() {
      final next = (_tabController.animation!.value).round();
      if (next != _selectedTab) setState(() => _selectedTab = next);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final allPhotos = company.branches.expand((b) => b.photos).toList();
    final coverUrl = company.coverPhotoUrl;

    // Compute real average rating across all active branches
    final activeBranches = company.branches.where((b) => b.isActive).toList();
    final totalReviews = activeBranches.fold<int>(
      0,
      (s, b) => s + b.reviewsCount,
    );
    final avgRating = totalReviews == 0
        ? 0.0
        : activeBranches.fold<double>(
                0,
                (s, b) => s + b.rating * b.reviewsCount,
              ) /
              totalReviews;
    final ratingChip = avgRating > 0
        ? '★ ${avgRating.toStringAsFixed(1)}'
        : '★ —';

    // Открыта ли сейчас хотя бы одна точка сети
    final openNow = isAnyOpenNow(activeBranches.map((b) => b.workingHours));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundApp,
        body: Column(
          children: [
            // ── Hero header (fixed height) ────────────────────────────
            SizedBox(
              height: _kHeaderHeight,
              child: _PharmacyHeroHeader(
                company: company,
                coverUrl: coverUrl,
                ratingChip: ratingChip,
                openNow: openNow,
              ),
            ),

            // ── Body overlaps header by _kOverlap via negative margin ─
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -_kOverlap),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundApp,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_kOverlap),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _SegmentedTabs(
                        selectedIndex: _selectedTab,
                        onTap: (i) {
                          setState(() => _selectedTab = i);
                          _tabController.animateTo(i);
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _AboutTab(company: company, allPhotos: allPhotos),
                            _BranchesTab(company: company),
                            _ReviewsTab(company: company),
                          ],
                        ),
                      ),
                    ],
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

// ─── _PharmacyHeroHeader ──────────────────────────────────────────────────────

class _PharmacyHeroHeader extends StatelessWidget {
  final PharmacyCompanyModel company;
  final String? coverUrl;
  final String ratingChip;
  final bool? openNow;
  const _PharmacyHeroHeader({
    required this.company,
    required this.coverUrl,
    required this.ratingChip,
    required this.openNow,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Base gradient ──────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),

        // ── Cover photo ────────────────────────────────────────────
        if (coverUrl != null)
          CachedNetworkImage(
            imageUrl: coverUrl!,
            fit: BoxFit.cover,
            errorWidget: (ctx, url, err) => const SizedBox.shrink(),
          ),

        // ── Dark vignette: лёгкий вверху + плотный чёрный внизу ─────
        // (фон не меняется — это просто затемнение для читаемости текста)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x66000000), // верх: лёгкое затемнение под статус-бар
                Color(0x1A000000), // середина: почти прозрачно
                Color(0x99000000), // ниже: начинает темнеть
                Color(0xE6000000), // низ: почти чёрный
              ],
              stops: [0.0, 0.32, 0.66, 1.0],
            ),
          ),
        ),

        // ── Content column ─────────────────────────────────────────
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  IconButton(
                    icon: const Icon(
                      PhosphorIconsRegular.shareNetwork,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: company.name));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Скопировано: ${company.name}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Рамка через foregroundDecoration — не уменьшает область изображения
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 3,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: company.logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: company.logoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (ctx, url, err) => const Icon(
                              PhosphorIconsRegular.pill,
                              color: AppColors.primaryBlue,
                              size: 34,
                            ),
                          )
                        : const Icon(
                            PhosphorIconsRegular.pill,
                            color: AppColors.primaryBlue,
                            size: 34,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    company.name,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      shadows: const [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Аптечная сеть',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      shadows: const [
                        Shadow(color: Color(0x40000000), blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HeroChip(text: ratingChip),
                      if (openNow != null) ...[
                        const SizedBox(width: 8),
                        _HeroChip(
                          text: openNow! ? 'Открыто' : 'Закрыто',
                          kind: openNow! ? _ChipKind.green : _ChipKind.red,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _ChipKind { neutral, green, red }

class _HeroChip extends StatelessWidget {
  final String text;
  final _ChipKind kind;
  const _HeroChip({required this.text, this.kind = _ChipKind.neutral});

  @override
  Widget build(BuildContext context) {
    final accent = switch (kind) {
      _ChipKind.green => AppColors.success,
      _ChipKind.red => AppColors.error,
      _ChipKind.neutral => Colors.white,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: kind == _ChipKind.neutral
            ? Colors.white.withValues(alpha: 0.18)
            : accent.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kind == _ChipKind.neutral
              ? Colors.white.withValues(alpha: 0.35)
              : accent.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          shadows: const [Shadow(color: Color(0x40000000), blurRadius: 4)],
        ),
      ),
    );
  }
}

// ─── _SegmentedTabs ───────────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _SegmentedTabs({required this.selectedIndex, required this.onTap});

  static const _labels = ['О аптеке', 'Филиалы', 'Отзывы'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final isActive = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelBold.copyWith(
                    fontSize: 13,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Вкладка «О аптеке» ────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final PharmacyCompanyModel company;
  final List<PharmacyBranchPhotoModel> allPhotos;

  const _AboutTab({required this.company, required this.allPhotos});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Горизонтальная галерея фото ────────────────────────────
        if (allPhotos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allPhotos.length,
              separatorBuilder: (context, i) => const SizedBox(width: 10),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: allPhotos[i].url,
                  width: 180,
                  height: 130,
                  fit: BoxFit.cover,
                  errorWidget: (ctx, url, err) => Container(
                    width: 180,
                    color: AppColors.backgroundApp,
                    child: const Icon(
                      PhosphorIconsRegular.image,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 8),

        // ── Контакты ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ContactCard(
            company: company,
            onCall: company.mainPhone != null
                ? () => _launch('tel:${company.mainPhone}')
                : null,
            onWhatsApp: company.whatsapp != null
                ? () => _launch(
                    'https://wa.me/${company.whatsapp!.replaceAll(RegExp(r'[^\d]'), '')}',
                  )
                : null,
            onInstagram: company.instagram != null
                ? () => _launch(
                    'https://instagram.com/${company.instagram!.replaceAll('@', '')}',
                  )
                : null,
            onSite: company.website != null
                ? () {
                    var url = company.website!;
                    if (!url.startsWith('http')) url = 'https://$url';
                    _launch(url);
                  }
                : null,
          ),
        ),

        // ── О аптеке ──────────────────────────────────────────────
        if (company.description != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _InfoCard(
              icon: PhosphorIconsRegular.info,
              iconColor: AppColors.accentBlue,
              title: 'О аптеке',
              content: company.description!,
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── _ContactCard ─────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final PharmacyCompanyModel company;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onInstagram;
  final VoidCallback? onSite;

  const _ContactCard({
    required this.company,
    this.onCall,
    this.onWhatsApp,
    this.onInstagram,
    this.onSite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Контакты', style: AppTextStyles.headingMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: PhosphorIconsRegular.phone,
                  label: 'Позвонить',
                  bgColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  iconColor: AppColors.primaryBlue,
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactButton(
                  icon: PhosphorIconsRegular.whatsappLogo,
                  label: 'WhatsApp',
                  bgColor: const Color(0xFF25D366).withValues(alpha: 0.1),
                  iconColor: const Color(0xFF25D366),
                  onTap: onWhatsApp,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: PhosphorIconsRegular.instagramLogo,
                  label: 'Instagram',
                  bgColor: const Color(0xFFE1306C).withValues(alpha: 0.1),
                  iconColor: const Color(0xFFE1306C),
                  onTap: onInstagram,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactButton(
                  icon: PhosphorIconsRegular.globe,
                  label: 'Сайт',
                  bgColor: AppColors.accentBlue.withValues(alpha: 0.1),
                  iconColor: AppColors.accentBlue,
                  onTap: onSite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── _ContactButton ───────────────────────────────────────────────────────────

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1.0 : 0.38,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelBold.copyWith(
                    color: iconColor,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _InfoCard ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Вкладка «Филиалы» ─────────────────────────────────────────────────────

class _BranchesTab extends StatefulWidget {
  final PharmacyCompanyModel company;
  const _BranchesTab({required this.company});

  @override
  State<_BranchesTab> createState() => _BranchesTabState();
}

class _BranchesTabState extends State<_BranchesTab> {
  PharmacyBranchModel? _nearest;
  bool _loadingNearest = false;

  Future<void> _findNearest() async {
    setState(() => _loadingNearest = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Разрешите геолокацию в настройках телефона'),
            ),
          );
        }
        setState(() => _loadingNearest = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final active = widget.company.branches
          .where((b) => b.isActive && b.latitude != null && b.longitude != null)
          .toList();

      if (active.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет филиалов с координатами')),
          );
        }
        setState(() => _loadingNearest = false);
        return;
      }

      active.sort((a, b) {
        final da = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          a.latitude!,
          a.longitude!,
        );
        final db = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          b.latitude!,
          b.longitude!,
        );
        return da.compareTo(db);
      });

      setState(() {
        _nearest = active.first;
        _loadingNearest = false;
      });
    } catch (_) {
      setState(() => _loadingNearest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.company.branches.where((b) => b.isActive).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // «Ближайший» кнопка
        GestureDetector(
          onTap: _loadingNearest ? null : _findNearest,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.accentBlue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loadingNearest)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(
                    PhosphorIconsRegular.navigationArrow,
                    color: Colors.white,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Text(
                  'Ближайший филиал',
                  style: AppTextStyles.labelBold.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        if (_nearest != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.mapPin,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _nearest!.address ?? 'Ближайший',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      context.push('/main/pharmacies/branch/${_nearest!.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Открыть',
                      style: AppTextStyles.labelBold.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        Row(
          children: [
            Text('Все филиалы', style: AppTextStyles.headingMedium),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${active.length}',
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (active.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Нет активных филиалов',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...active.map(
            (b) => GestureDetector(
              onTap: () => context.push('/main/pharmacies/branch/${b.id}'),
              child: PharmacyBranchCard(
                branch: b,
                fallbackLogoUrl: widget.company.logoUrl,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Вкладка «Отзывы» ──────────────────────────────────────────────────────

class _ReviewsTab extends ConsumerWidget {
  final PharmacyCompanyModel company;
  const _ReviewsTab({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBranches = company.branches.where((b) => b.isActive).toList();

    if (activeBranches.isEmpty) {
      return Center(
        child: Text(
          'Нет активных филиалов',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final totalReviews = activeBranches.fold<int>(
      0,
      (s, b) => s + b.reviewsCount,
    );
    final avgRating = totalReviews == 0
        ? 0.0
        : activeBranches.fold<double>(
                0,
                (s, b) => s + b.rating * b.reviewsCount,
              ) /
              totalReviews;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Сводная статистика
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.primaryBlue,
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avgRating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$totalReviews ${_pluralReview(totalReviews)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...activeBranches
            .where((b) => b.reviewsCount > 0)
            .map((b) => _BranchRatingRow(branch: b)),
      ],
    );
  }

  String _pluralReview(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'отзыв';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'отзыва';
    }
    return 'отзывов';
  }
}

class _BranchRatingRow extends StatelessWidget {
  final PharmacyBranchModel branch;
  const _BranchRatingRow({required this.branch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.address ?? 'Филиал',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < branch.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.warning,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${branch.rating.toStringAsFixed(1)} (${branch.reviewsCount})',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/main/pharmacies/branch/${branch.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Отзывы',
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer ───────────────────────────────────────────────────────────────

class _CompanyShimmer extends StatelessWidget {
  const _CompanyShimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Container(height: 320, color: Colors.white),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(
                  4,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
