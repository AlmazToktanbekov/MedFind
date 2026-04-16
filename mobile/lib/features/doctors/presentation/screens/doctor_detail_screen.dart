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
import '../../providers/doctors_provider.dart';
import '../../providers/reviews_provider.dart';
import '../../data/reviews_repository.dart';

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
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
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
                          errorWidget: (_, __, ___) => const _PhotoPlaceholder(),
                        )
                      : const _PhotoPlaceholder(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        indicatorColor: Colors.white,
        tabs: const [
          Tab(text: 'О враче'),
          Tab(text: 'Отзывы'),
        ],
      ),
    );
  }
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

          if (doctor.bio != null) ...[
            const SizedBox(height: 20),
            Text('О враче', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(doctor.bio!, style: AppTextStyles.bodyLarge),
          ],

          const SizedBox(height: 24),
          Text('Тип визита', style: AppTextStyles.headingMedium),
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
                    onTap: () => onOpenUrl('https://wa.me/${doctor.whatsapp}'),
                  ),
                if (doctor.telegram != null)
                  _ContactButton(
                    label: 'Telegram',
                    color: const Color(0xFF0088CC),
                    icon: Icons.send_rounded,
                    onTap: () => onOpenUrl('https://t.me/${doctor.telegram}'),
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
                    onTap: () => onOpenUrl('tel:${doctor.phone}'),
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ReviewCard(review: state.reviews[i]),
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

// ─── Review card ───────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  String get _initials {
    final name = review.authorName ?? '';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get _formattedDate {
    final d = review.createdAt.toLocal();
    final months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  _initials,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName ?? 'Аноним',
                      style: AppTextStyles.labelBold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(_formattedDate, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              // Рейтинг
              Row(
                children: [
                  Icon(Icons.star_rounded, color: const Color(0xFFFFB800), size: 16),
                  const SizedBox(width: 2),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: AppTextStyles.labelBold.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (review.text != null && review.text!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.text!, style: AppTextStyles.bodyLarge),
          ],
        ],
      ),
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
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
            if (price != null)
              Text(
                '${price!.toInt()} сом',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textSecondary,
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
