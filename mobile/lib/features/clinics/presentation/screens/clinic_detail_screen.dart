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
import '../../providers/clinics_provider.dart';

class ClinicDetailScreen extends ConsumerWidget {
  final String clinicId;
  const ClinicDetailScreen({super.key, required this.clinicId});

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(clinicId) ?? 0;
    final clinicAsync = ref.watch(clinicByIdProvider(id));

    return clinicAsync.when(
      loading: () => const _ClinicDetailShimmer(),
      error: (_, __) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primaryDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('Не удалось загрузить клинику',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.refresh(clinicByIdProvider(id)),
                child: Text('Повторить', style: AppTextStyles.labelBold),
              ),
            ],
          ),
        ),
      ),
      data: (clinic) => _buildScaffold(context, clinic),
    );
  }

  Widget _buildScaffold(BuildContext context, ClinicModel clinic) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: CustomScrollView(
        slivers: [
          _buildHero(context, clinic),
          SliverToBoxAdapter(child: _buildBody(context, clinic)),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, ClinicModel clinic) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: clinic.photoUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: clinic.photoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _gradientBg(clinic),
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.35)),
                ],
              )
            : _gradientBg(clinic),
        title: Text(
          clinic.name,
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _gradientBg(ClinicModel clinic) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      alignment: Alignment.center,
      child: const Icon(PhosphorIconsRegular.hospital,
          color: Colors.white, size: 64),
    );
  }

  Widget _buildBody(BuildContext context, ClinicModel clinic) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Рейтинг
          RatingStars(rating: clinic.rating, reviewCount: clinic.reviewsCount),

          // Категория
          if (clinic.category != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.backgroundChip,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(clinic.category!, style: AppTextStyles.labelBold),
            ),
          ],

          // Описание
          if (clinic.description != null) ...[
            const SizedBox(height: 20),
            Text('О клинике', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(clinic.description!, style: AppTextStyles.bodyLarge),
          ],

          // Инфо карточки
          const SizedBox(height: 20),
          _InfoGrid(clinic: clinic),

          // Контакты
          const SizedBox(height: 24),
          Text('Контакты', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),
          if (clinic.phone != null)
            _InfoRow(
              icon: PhosphorIconsRegular.phone,
              text: clinic.phone!,
              onTap: () => _call(clinic.phone!),
            ),
          if (clinic.website != null)
            _InfoRow(
              icon: PhosphorIconsRegular.globe,
              text: clinic.website!,
              onTap: () => _openUrl(
                clinic.website!.startsWith('http')
                    ? clinic.website!
                    : 'https://${clinic.website}',
              ),
            ),

          const SizedBox(height: 32),
          GradientButton(
            text: 'Позвонить',
            onPressed: clinic.phone != null ? () => _call(clinic.phone!) : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final ClinicModel clinic;
  const _InfoGrid({required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (clinic.address != null)
          _InfoRow(
            icon: PhosphorIconsRegular.mapPin,
            text: clinic.address!,
          ),
        if (clinic.workingHours != null)
          _InfoRow(
            icon: PhosphorIconsRegular.clock,
            text: clinic.workingHours!,
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InfoRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: onTap != null ? AppColors.primaryBlue : AppColors.textPrimary,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(PhosphorIconsRegular.arrowRight,
                  color: AppColors.primaryBlue, size: 16),
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
            Container(height: 220, color: Colors.white),
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
