import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/doctor_model.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../../shared/widgets/review_card.dart';
import '../../providers/doctors_provider.dart';
import '../../providers/reviews_provider.dart';
import '../../../../core/analytics/analytics_tracker.dart';

class DoctorDetailScreen extends ConsumerStatefulWidget {
  final String doctorId;
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _visitType = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final id = int.tryParse(widget.doctorId);
    if (id != null) AnalyticsTracker().viewDoctor(id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(widget.doctorId) ?? 0;
    final doctorAsync = ref.watch(doctorByIdProvider(id));

    return doctorAsync.when(
      loading: () => const _DetailShimmer(),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text('Не удалось загрузить профиль',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.refresh(doctorByIdProvider(id)),
                child: Text('Повторить', style: AppTextStyles.labelBold),
              ),
            ],
          ),
        ),
      ),
      data: (doctor) => _buildScaffold(doctor),
    );
  }

  Widget _buildScaffold(DoctorModel doctor) {
    final id = doctor.id;
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(doctor),
          _buildSliverTabBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _AboutTab(
              doctor: doctor,
              visitType: _visitType,
              onVisitTypeChanged: (v) => setState(() => _visitType = v),
              onOpenUrl: _openUrl,
            ),
            _ReviewsTab(doctorId: id),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 2.5,
          labelStyle: AppTextStyles.labelBold,
          unselectedLabelStyle: AppTextStyles.bodySmall,
          tabs: const [
            Tab(text: 'О враче'),
            Tab(text: 'Отзывы'),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(DoctorModel doctor) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      forceElevated: true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(PhosphorIconsRegular.shareNetwork, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image or gradient
            if (doctor.coverPhotoUrl != null)
              CachedNetworkImage(
                imageUrl: doctor.coverPhotoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                ),
                errorWidget: (_, _, _) => Container(
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              ),
            // Dark gradient overlay for text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 1.0],
                  colors: [
                    Color(0x55000000),
                    Color(0x22000000),
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Активен',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor.fullName,
                      style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
                    ),
                    Text(
                      doctor.specialization,
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    if (doctor.experienceYears != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Опыт: ${doctor.experienceYears} лет',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Hero(
                tag: 'doctor_${doctor.id}',
                child: Container(
                  width: 90,
                  height: 110,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: doctor.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: doctor.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const _PhotoPlaceholder(),
                          errorWidget: (_, _, _) => const _PhotoPlaceholder(),
                        )
                      : const _PhotoPlaceholder(),
                ),
              ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ─── О враче tab ───────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  final DoctorModel doctor;
  final int visitType;
  final ValueChanged<int> onVisitTypeChanged;
  final Future<void> Function(String) onOpenUrl;

  const _AboutTab({
    required this.doctor,
    required this.visitType,
    required this.onVisitTypeChanged,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingStars(
            rating: doctor.rating,
            reviewCount: doctor.reviewCount,
            iconSize: 18,
          ),

          // ── Подтверждён клиникой ────────────────────────────────────
          if (doctor.clinicId != null && doctor.clinicName != null) ...[
            const SizedBox(height: 16),
            _ClinicBadge(
              clinicId: doctor.clinicId!,
              clinicName: doctor.clinicName!,
            ),
          ],

          if (doctor.bio != null) ...[
            const SizedBox(height: 20),
            Text('О враче', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(doctor.bio!, style: AppTextStyles.bodyLarge),
          ],

          // ── Образование ──────────────────────────────────────────────
          if (doctor.education != null) ...[
            const SizedBox(height: 20),
            Text('Образование', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(doctor.education!, style: AppTextStyles.bodyLarge),
          ],

          const SizedBox(height: 24),
          Text('Консультация', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              if (doctor.hasOffline)
                Expanded(
                  child: _VisitTypeCard(
                    title: 'Очный',
                    price: doctor.offlinePrice,
                    duration: doctor.offlineDurationMin,
                    isActive: visitType == 0,
                    onTap: () => onVisitTypeChanged(0),
                  ),
                ),
              if (doctor.hasOffline && doctor.hasOnline) const SizedBox(width: 12),
              if (doctor.hasOnline)
                Expanded(
                  child: _VisitTypeCard(
                    title: 'Онлайн',
                    price: doctor.onlinePrice,
                    duration: doctor.onlineDurationMin,
                    isActive: visitType == 1,
                    onTap: () => onVisitTypeChanged(1),
                  ),
                ),
            ],
          ),

          if (doctor.services.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Услуги', style: AppTextStyles.headingMedium),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < doctor.services.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.backgroundApp,
                        indent: 16,
                        endIndent: 16,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              doctor.services[i].name,
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (doctor.services[i].price != null)
                            Text(
                              '${doctor.services[i].price!.toInt()} сом',
                              style: AppTextStyles.labelBold.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (doctor.contacts.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Контакты', style: AppTextStyles.headingMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (doctor.whatsapp != null)
                  _ContactButton(
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    icon: Icons.message_rounded,
                    onTap: () {
                      AnalyticsTracker().clickWhatsapp('doctor', doctor.id);
                      onOpenUrl('https://wa.me/${doctor.whatsapp}');
                    },
                  ),
                if (doctor.telegram != null)
                  _ContactButton(
                    label: 'Telegram',
                    color: const Color(0xFF0088CC),
                    icon: Icons.send_rounded,
                    onTap: () {
                      AnalyticsTracker().clickTelegram('doctor', doctor.id);
                      onOpenUrl('https://t.me/${doctor.telegram}');
                    },
                  ),
                if (doctor.instagram != null)
                  _ContactButton(
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                    icon: Icons.camera_alt_rounded,
                    onTap: () =>
                        onOpenUrl('https://instagram.com/${doctor.instagram}'),
                  ),
                if (doctor.phone != null)
                  _ContactButton(
                    label: 'Позвонить',
                    color: AppColors.primaryBlue,
                    icon: PhosphorIconsRegular.phone,
                    onTap: () {
                      AnalyticsTracker().clickCall('doctor', doctor.id);
                      onOpenUrl('tel:${doctor.phone}');
                    },
                  ),
              ],
            ),
          ],

          const SizedBox(height: 32),
          GradientButton(text: 'Записаться', onPressed: () {}),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Отзывы tab ────────────────────────────────────────────────────────────

class _ReviewsTab extends ConsumerWidget {
  final int doctorId;
  const _ReviewsTab({required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewsProvider(doctorId));

    if (state.isLoading) return const _ReviewsShimmer();

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(state.error!, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(reviewsProvider(doctorId).notifier).load(),
              child: Text('Повторить', style: AppTextStyles.labelBold),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        state.reviews.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.chatCircle,
                        size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('Отзывов пока нет',
                        style: AppTextStyles.headingMedium
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Будьте первым, кто оставит отзыв',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: state.reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => ReviewCard(
                  review: state.reviews[i],
                  onUpdate: ref.read(reviewsProvider(doctorId).notifier).update,
                  onDelete: ref.read(reviewsProvider(doctorId).notifier).delete,
                ),
              ),

        // Кнопка "Написать отзыв"
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _WriteReviewButton(doctorId: doctorId),
        ),
      ],
    );
  }
}

// ─── Write review button ───────────────────────────────────────────────────

class _WriteReviewButton extends ConsumerWidget {
  final int doctorId;
  const _WriteReviewButton({required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.accentBlue],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextButton.icon(
          onPressed: () => _showReviewSheet(context, ref),
          icon: const Icon(PhosphorIconsRegular.pencilSimple, color: Colors.white, size: 18),
          label: Text(
            'Написать отзыв',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewFormSheet(doctorId: doctorId),
    );
  }
}

// ─── Review form bottom sheet ──────────────────────────────────────────────

class _ReviewFormSheet extends ConsumerStatefulWidget {
  final int doctorId;
  const _ReviewFormSheet({required this.doctorId});

  @override
  ConsumerState<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<_ReviewFormSheet> {
  int _selectedStars = 0;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewsProvider(widget.doctorId));
    final notifier = ref.read(reviewsProvider(widget.doctorId).notifier);

    // Close sheet on success
    ref.listen<ReviewsState>(reviewsProvider(widget.doctorId), (_, next) {
      if (next.justSubmitted && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Спасибо за отзыв!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          const SizedBox(height: 20),

          // Stars
          Text('Оценка', style: AppTextStyles.labelBold),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final filled = i < _selectedStars;
              return GestureDetector(
                onTap: () => setState(() => _selectedStars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? const Color(0xFFFFB800) : Colors.grey.shade300,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Text
          Text('Комментарий', style: AppTextStyles.labelBold),
          const SizedBox(height: 10),
          TextField(
            controller: _textController,
            maxLines: 4,
            maxLength: 500,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Расскажите о своём опыте...',
              hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.backgroundApp,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
              counterStyle: AppTextStyles.bodySmall,
            ),
          ),

          // Error
          if (state.submitError != null) ...[
            const SizedBox(height: 8),
            Text(
              state.submitError!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _selectedStars == 0
                    ? LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade300])
                    : LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.accentBlue]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextButton(
                onPressed: state.isSubmitting || _selectedStars == 0
                    ? null
                    : () async {
                        await notifier.submit(
                          _selectedStars.toDouble(),
                          _textController.text,
                        );
                      },
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Отправить',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _selectedStars == 0 ? Colors.grey : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reviews shimmer ────────────────────────────────────────────────────────

class _ReviewsShimmer extends StatelessWidget {
  const _ReviewsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ─── Visit type card ───────────────────────────────────────────────────────

class _VisitTypeCard extends StatelessWidget {
  final String title;
  final double? price;
  final int? duration;
  final bool isActive;
  final VoidCallback onTap;

  const _VisitTypeCard({
    required this.title,
    this.price,
    this.duration,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.labelBold.copyWith(
                color: isActive ? Colors.white : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            if (duration != null)
              Text(
                '$duration мин',
                style: AppTextStyles.headingMedium.copyWith(
                  color: isActive ? Colors.white : AppColors.textPrimary,
                  fontSize: 22,
                ),
              ),
            Text(
              (price == null || price == 0) ? 'Бесплатно' : '${price!.toInt()} сом',
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.8)
                    : (price == null || price == 0)
                        ? AppColors.success
                        : AppColors.textSecondary,
                fontWeight: (price == null || price == 0)
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Contact button ────────────────────────────────────────────────────────

class _ContactButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ContactButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
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

// ─── Photo placeholder ─────────────────────────────────────────────────────

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(PhosphorIconsRegular.userCircle, color: Colors.white, size: 50);
  }
}

// ─── Detail shimmer ────────────────────────────────────────────────────────

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
            Container(height: 280, color: Colors.white),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 180, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16))),
                  const SizedBox(height: 12),
                  Container(
                      height: 80,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Clinic badge ──────────────────────────────────────────────────────────

class _ClinicBadge extends StatelessWidget {
  final int clinicId;
  final String clinicName;

  const _ClinicBadge({required this.clinicId, required this.clinicName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/main/clinics/$clinicId'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded,
                color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall,
                  children: [
                    const TextSpan(
                      text: 'Подтверждён клиникой: ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: clinicName,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppColors.success.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
