import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/content_repository.dart';
import '../../providers/content_provider.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(healthContentProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: contentAsync.when(
        loading: () => const _HealthShimmer(),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('Не удалось загрузить контент',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.refresh(healthContentProvider),
                child: Text('Повторить', style: AppTextStyles.labelBold),
              ),
            ],
          ),
        ),
        data: (content) => CustomScrollView(
          slivers: [
            _buildHeader(),
            if (content.firstAid.isNotEmpty)
              _SectionHeader(
                icon: PhosphorIconsRegular.firstAid,
                title: 'Первая помощь',
                color: AppColors.error,
              ),
            if (content.firstAid.isNotEmpty)
              _HorizontalCardList(items: content.firstAid),
            if (content.articles.isNotEmpty)
              _SectionHeader(
                icon: PhosphorIconsRegular.newspaper,
                title: 'Статьи',
                color: AppColors.primaryBlue,
              ),
            if (content.articles.isNotEmpty)
              _VerticalArticleList(items: content.articles),
            if (content.tips.isNotEmpty)
              _SectionHeader(
                icon: PhosphorIconsRegular.lightbulb,
                title: 'Советы по здоровью',
                color: AppColors.success,
              ),
            if (content.tips.isNotEmpty)
              _HorizontalCardList(items: content.tips),
            if (content.articles.isEmpty &&
                content.firstAid.isEmpty &&
                content.tips.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsRegular.heartbeat,
                          size: 64,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('Контент скоро появится',
                          style: AppTextStyles.headingMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Здоровье',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Полезные статьи и советы',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title, style: AppTextStyles.headingMedium),
          ],
        ),
      ),
    );
  }
}

// ─── Horizontal card list (first aid, tips) ────────────────────────────────

class _HorizontalCardList extends StatelessWidget {
  final List<ArticleModel> items;
  const _HorizontalCardList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (_, i) => _HorizontalCard(article: items[i]),
        ),
      ),
    );
  }
}

class _HorizontalCard extends StatelessWidget {
  final ArticleModel article;
  const _HorizontalCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: article.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _ImagePlaceholder(),
                  )
                : const _ImagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              article.title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vertical article list ─────────────────────────────────────────────────

class _VerticalArticleList extends StatelessWidget {
  final List<ArticleModel> items;
  const _VerticalArticleList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _ArticleRow(article: items[i]),
        childCount: items.length,
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final ArticleModel article;
  const _ArticleRow({required this.article});

  String get _date {
    final d = article.createdAt.toLocal();
    final months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.backgroundApp,
            ),
            clipBehavior: Clip.antiAlias,
            child: article.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _ImagePlaceholder(),
                  )
                : const _ImagePlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(_date, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ─── Image placeholder ─────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryBlue.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(PhosphorIconsRegular.image,
            color: AppColors.primaryBlue, size: 28),
      ),
    );
  }
}

// ─── Shimmer ───────────────────────────────────────────────────────────────

class _HealthShimmer extends StatelessWidget {
  const _HealthShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 120, color: Colors.white),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                  height: 20, width: 140, color: Colors.white),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                  height: 20, width: 100, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              3,
              (_) => Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
