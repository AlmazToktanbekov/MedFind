import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/pharmacies_provider.dart';
import '../../utils/pharmacy_hours.dart';
import '../../../doctors/providers/reviews_provider.dart';
import '../../../../shared/widgets/review_card.dart';
import '../../../../shared/widgets/report_dialog.dart';
class PharmacyDetailScreen extends ConsumerWidget {
  final String pharmacyId;
  const PharmacyDetailScreen({super.key, required this.pharmacyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(pharmacyId) ?? 0;
    final branchAsync = ref.watch(branchByIdProvider(id));

    return branchAsync.when(
      loading: () => const _DetailShimmer(),
      error: (e, s) => Scaffold(
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
            ],
          ),
        ),
      ),
      data: (branch) => _BranchScaffold(branch: branch),
    );
  }
}

// ─── Main scaffold — clinic-style ─────────────────────────────────────────

class _BranchScaffold extends ConsumerWidget {
  final PharmacyBranchModel branch;
  const _BranchScaffold({required this.branch});

  String? get _phone => branch.phone ?? branch.companyMainPhone;

  Future<void> _call() async {
    final phone = _phone;
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMap() async {
    final lat = branch.latitude;
    final lon = branch.longitude;
    if (lat == null || lon == null) return;
    final name = Uri.encodeComponent(branch.companyName ?? 'Аптека');
    final dgis = Uri.parse('dgis://2gis.ru/routeSearch/to/$lat,$lon');
    if (await canLaunchUrl(dgis)) {
      await launchUrl(dgis, mode: LaunchMode.externalApplication);
      return;
    }
    final gmaps = Uri.parse('https://maps.google.com/?q=$lat,$lon($name)');
    await launchUrl(gmaps, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp() async {
    final phone = branch.companyWhatsapp;
    if (phone == null) return;
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInstagram() async {
    final handle = branch.companyInstagram;
    if (handle == null) return;
    final clean = handle.replaceAll('@', '');
    final uri = Uri.parse('https://instagram.com/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openSite() async {
    var url = branch.companyWebsite;
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _share(BuildContext context) {
    final name = branch.companyName ?? 'Аптека';
    final text =
        branch.address != null ? '$name — ${branch.address}' : name;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Скопировано: $text'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav =
        ref.watch(favoritesProvider).contains('pharmacy_branch:${branch.id}');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundApp,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // ── 1. Фото-шапка ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.primaryDark,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.shareNetwork,
                      color: Colors.white),
                  onPressed: () => _share(context),
                ),
                IconButton(
                  icon: Icon(
                    isFav
                        ? PhosphorIconsFill.heart
                        : PhosphorIconsRegular.heart,
                    color: isFav ? AppColors.error : Colors.white,
                  ),
                  onPressed: () => ref
                      .read(favoritesProvider.notifier)
                      .toggle('pharmacy_branch', branch.id),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.flag,
                      color: Colors.white),
                  tooltip: 'Пожаловаться',
                  onPressed: () => ReportDialog.show(
                    context,
                    targetType: 'pharmacy_branch',
                    targetId: branch.id,
                    targetTitle: branch.address,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: branch.photos.isNotEmpty
                    ? _PhotoGallery(photos: branch.photos)
                    : _GradientBg(logoUrl: branch.companyLogoUrl),
              ),
            ),

            // ── 2. Белая карточка: название + адрес + кнопки ─────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Логотип компании + название + адрес филиала
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Лого компании
                        if (branch.companyLogoUrl != null)
                          Container(
                            width: 52,
                            height: 52,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.12),
                                width: 1.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: branch.companyLogoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => const ColoredBox(
                                color: Color(0xFFEEF2FF),
                                child: Icon(PhosphorIconsRegular.pill,
                                    color: AppColors.primaryBlue, size: 22),
                              ),
                              errorWidget: (ctx, url, err) => const ColoredBox(
                                color: Color(0xFFEEF2FF),
                                child: Icon(PhosphorIconsRegular.pill,
                                    color: AppColors.primaryBlue, size: 22),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (branch.companyName != null)
                                Text(
                                  branch.companyName!,
                                  style: AppTextStyles.headingMedium
                                      .copyWith(fontSize: 19),
                                ),
                              if (branch.address != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(PhosphorIconsRegular.mapPin,
                                        size: 12,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        branch.address!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatBadge(
                          icon: PhosphorIconsFill.star,
                          iconColor: AppColors.warning,
                          text: branch.reviewsCount > 0
                              ? '${branch.rating.toStringAsFixed(1)} · ${branch.reviewsCount}'
                              : 'Нет отзывов',
                        ),
                        const SizedBox(width: 8),
                        Builder(builder: (_) {
                          final open = isPharmacyOpenNow(branch.workingHours);
                          if (open == null) return const SizedBox.shrink();
                          return _StatBadge(
                            icon: PhosphorIconsFill.clock,
                            iconColor: open
                                ? AppColors.success
                                : AppColors.error,
                            text: open ? 'Открыто' : 'Закрыто',
                            textColor: open
                                ? AppColors.success
                                : AppColors.error,
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_phone != null || branch.latitude != null) ...[
                      Row(
                        children: [
                          if (_phone != null)
                            Expanded(
                              child: GradientButton(
                                text: 'Позвонить',
                                onPressed: _call,
                              ),
                            ),
                          if (_phone != null && branch.latitude != null)
                            const SizedBox(width: 10),
                          if (branch.latitude != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openMap,
                                icon: const Icon(
                                    PhosphorIconsRegular.navigationArrow,
                                    size: 16),
                                label: const Text('Маршрут'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  side: const BorderSide(
                                      color: AppColors.primaryBlue),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // ── 3. Прилипающие вкладки ────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBar(),
            ),
          ],
          body: TabBarView(
            children: [
              _InfoTab(
                branch: branch,
                onWhatsApp:
                    branch.companyWhatsapp != null ? _openWhatsApp : null,
                onInstagram:
                    branch.companyInstagram != null ? _openInstagram : null,
                onSite: (branch.companyWebsite != null &&
                        branch.companyWebsite!.isNotEmpty)
                    ? _openSite
                    : null,
              ),
              _ReviewsTab(
                branchId: branch.id,
                branchRating: branch.rating,
                branchReviewsCount: branch.reviewsCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Маленький бейдж со статусом/рейтингом ────────────────────────────────

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color? textColor;

  const _StatBadge({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (textColor ?? AppColors.textSecondary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sticky tab bar ────────────────────────────────────────────────────────

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  static const double _height = 52;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
                  Tab(text: 'О филиале'),
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

// ─── Вкладка «О филиале» ──────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final PharmacyBranchModel branch;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onInstagram;
  final VoidCallback? onSite;

  const _InfoTab({
    required this.branch,
    this.onWhatsApp,
    this.onInstagram,
    this.onSite,
  });

  @override
  Widget build(BuildContext context) {
    final is24h = branch.workingHours == 'Круглосуточно';
    final scheduleSlots = _parseSchedule(branch.workingHours);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // График работы
        Text('График работы', style: AppTextStyles.headingMedium),
        const SizedBox(height: 10),
        if (is24h)
          _Badge24h()
        else if (scheduleSlots.isNotEmpty)
          _ScheduleScroll(slots: scheduleSlots)
        else if (branch.workingHours != null)
          Text(branch.workingHours!,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary))
        else
          Text('Не указан',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary)),

        // WhatsApp / Instagram / Сайт
        if (onWhatsApp != null || onInstagram != null || onSite != null) ...[
          const SizedBox(height: 20),
          Text('Контакты', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onWhatsApp != null)
                _ContactChip(
                  icon: PhosphorIconsRegular.whatsappLogo,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: onWhatsApp!,
                ),
              if (onInstagram != null)
                _ContactChip(
                  icon: PhosphorIconsRegular.instagramLogo,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: onInstagram!,
                ),
              if (onSite != null)
                _ContactChip(
                  icon: PhosphorIconsRegular.globe,
                  label: 'Сайт',
                  color: AppColors.accentBlue,
                  onTap: onSite!,
                ),
            ],
          ),
        ],

        if (branch.distanceKm != null) ...[
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsRegular.navigationArrow,
                    size: 14, color: AppColors.primaryBlue),
                const SizedBox(width: 6),
                Text(
                  '${branch.distanceKm!.toStringAsFixed(1)} км от вас',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<_ScheduleSlot> _parseSchedule(String? raw) {
    if (raw == null || raw == 'Круглосуточно') return [];
    final slots = <_ScheduleSlot>[];
    for (final part in raw.split(', ')) {
      final s = part.trim();
      if (s.isEmpty) continue;
      final spaceIdx = s.indexOf(' ');
      if (spaceIdx < 0) continue;
      slots.add(_ScheduleSlot(
        day: s.substring(0, spaceIdx),
        hours: s.substring(spaceIdx + 1),
      ));
    }
    return slots;
  }
}

class _ScheduleSlot {
  final String day;
  final String hours;
  const _ScheduleSlot({required this.day, required this.hours});
}

class _Badge24h extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsRegular.clock,
              color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Text('Круглосуточно',
              style: AppTextStyles.labelBold
                  .copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}

class _ScheduleScroll extends StatelessWidget {
  final List<_ScheduleSlot> slots;
  const _ScheduleScroll({required this.slots});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final slot = slots[i];
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slot.day,
                    style: AppTextStyles.labelBold.copyWith(
                        color: AppColors.primaryBlue, fontSize: 13)),
                const SizedBox(height: 2),
                Text(slot.hours,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.labelBold
                    .copyWith(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Вкладка «Отзывы» ─────────────────────────────────────────────────────

class _ReviewsTab extends ConsumerWidget {
  final int branchId;
  final double branchRating;
  final int branchReviewsCount;
  const _ReviewsTab({
    required this.branchId,
    required this.branchRating,
    required this.branchReviewsCount,
  });

  String _pluralReview(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'отзыв';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'отзыва';
    }
    return 'отзывов';
  }

  void _openWriteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(branchId: branchId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchReviewsProvider(branchId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ── Сводка: оценка + кнопка «Написать отзыв» ─────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    branchReviewsCount > 0
                        ? branchRating.toStringAsFixed(1)
                        : '—',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < branchRating.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        branchReviewsCount > 0
                            ? '$branchReviewsCount ${_pluralReview(branchReviewsCount)}'
                            : 'Пока нет отзывов',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'Написать отзыв',
                  onPressed: () => _openWriteSheet(context),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text('Отзывы', style: AppTextStyles.headingMedium),
        const SizedBox(height: 12),

        if (state.isLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
        else if (state.error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Не удалось загрузить отзывы',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
            ),
          )
        else if (state.reviews.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                const Icon(PhosphorIconsRegular.chatCircleText,
                    size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 10),
                Text('Пока нет отзывов',
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Будьте первым, кто оставит отзыв',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          )
        else
          ...state.reviews.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ReviewCard(
              review: r,
              onUpdate: ref.read(branchReviewsProvider(branchId).notifier).update,
              onDelete: ref.read(branchReviewsProvider(branchId).notifier).delete,
            ),
          )),
      ],
    );
  }
}

// ─── Bottom sheet «Написать отзыв» ────────────────────────────────────────

class _WriteReviewSheet extends ConsumerStatefulWidget {
  final int branchId;
  const _WriteReviewSheet({required this.branchId});

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  final _reviewCtrl = TextEditingController();
  double _rating = 5;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _reviewCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напишите текст отзыва')),
      );
      return;
    }
    final notifier = ref.read(branchReviewsProvider(widget.branchId).notifier);
    final ok = await notifier.submit(_rating, text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Спасибо за отзыв!')),
      );
    } else {
      final err = ref.read(branchReviewsProvider(widget.branchId)).submitError;
      notifier.clearSubmitError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Не удалось отправить отзыв'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        ref.watch(branchReviewsProvider(widget.branchId)).isSubmitting;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Написать отзыв', style: AppTextStyles.headingMedium),
            const SizedBox(height: 4),
            Text('Поставьте оценку и поделитесь впечатлением',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = (i + 1).toDouble();
                  return GestureDetector(
                    onTap: () => setState(() => _rating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _rating >= star
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.warning,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewCtrl,
              maxLines: 4,
              autofocus: true,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Напишите ваш отзыв...',
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
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
              child: GradientButton(
                text: 'Отправить',
                isLoading: isSubmitting,
                onPressed: isSubmitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo gallery ────────────────────────────────────────────────────────

class _PhotoGallery extends StatefulWidget {
  final List<PharmacyBranchPhotoModel> photos;
  const _PhotoGallery({required this.photos});

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (context, i) => CachedNetworkImage(
            imageUrl: widget.photos[i].url,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => const _GradientBg(),
            errorWidget: (ctx, url, err) => const _GradientBg(),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.primaryDark.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        if (widget.photos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.photos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _current
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GradientBg extends StatelessWidget {
  final String? logoUrl;
  const _GradientBg({this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: logoUrl != null
            ? CachedNetworkImage(
                imageUrl: logoUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                placeholder: (ctx, url) => const Icon(
                    PhosphorIconsRegular.pill,
                    color: Colors.white54,
                    size: 72),
                errorWidget: (ctx, url, err) => const Icon(
                    PhosphorIconsRegular.pill,
                    color: Colors.white54,
                    size: 72),
              )
            : const Icon(PhosphorIconsRegular.pill,
                color: Colors.white54, size: 72),
      ),
    );
  }
}

// ─── Shimmer ─────────────────────────────────────────────────────────────

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
            Container(
              height: 140,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 2),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  3,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 70,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
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
