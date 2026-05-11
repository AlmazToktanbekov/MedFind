import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/doctor_model.dart';
import 'rating_stars.dart';

class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            // Фото
            Hero(
              tag: 'doctor_${doctor.id}',
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundChip,
                ),
                clipBehavior: Clip.antiAlias,
                child: doctor.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: doctor.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const _AvatarPlaceholder(),
                        errorWidget: (_, _, _) => const _AvatarPlaceholder(),
                      )
                    : const _AvatarPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),

            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.specialization, style: AppTextStyles.labelBold),
                  const SizedBox(height: 2),
                  Text(
                    doctor.fullName,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  RatingStars(
                    rating: doctor.rating,
                    reviewCount: doctor.reviewCount,
                  ),
                ],
              ),
            ),

            // Кнопки справа
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onFavoriteToggle != null)
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isFavorite
                            ? PhosphorIconsFill.heart
                            : PhosphorIconsRegular.heart,
                        color: isFavorite
                            ? const Color(0xFFE53935)
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.arrowRight,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      PhosphorIconsRegular.userCircle,
      color: AppColors.textSecondary,
      size: 32,
    );
  }
}
