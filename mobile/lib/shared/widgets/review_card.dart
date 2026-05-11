import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/current_user_provider.dart';
import '../../features/doctors/data/reviews_repository.dart';

class ReviewCard extends ConsumerWidget {
  final ReviewModel review;
  final Future<bool> Function(int reviewId, double rating, String? text)? onUpdate;
  final Future<bool> Function(int reviewId)? onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    this.onUpdate,
    this.onDelete,
  });

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
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditReviewSheet(
        review: review,
        onSave: onUpdate,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить отзыв?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена',
                style: AppTextStyles.labelBold
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onDelete?.call(review.id);
            },
            child: Text('Удалить',
                style: AppTextStyles.labelBold.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserIdAsync = ref.watch(currentUserIdProvider);
    final isOwn = currentUserIdAsync.valueOrNull == review.authorId;

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
              _AuthorAvatar(
                avatarUrl: review.authorAvatarUrl,
                initials: _initials,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName ?? 'Аноним',
                      style: AppTextStyles.labelBold
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    Text(_formattedDate,
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFB800), size: 16),
                  const SizedBox(width: 2),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: AppTextStyles.labelBold
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
              if (isOwn && (onUpdate != null || onDelete != null)) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (val) {
                    if (val == 'edit') _showEditSheet(context);
                    if (val == 'delete') _confirmDelete(context);
                  },
                  itemBuilder: (_) => [
                    if (onUpdate != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Изменить'),
                        ]),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text('Удалить',
                              style: TextStyle(color: AppColors.error)),
                        ]),
                      ),
                  ],
                ),
              ],
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

// ─── Author avatar ────────────────────────────────────────────────────────────

class _AuthorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;

  const _AuthorAvatar({required this.avatarUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl != null ? AppConstants.fixUrl(avatarUrl!) : null;
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      child: url != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _Initials(initials),
              ),
            )
          : _Initials(initials),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  const _Initials(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryBlue,
        ),
      );
}

// ─── Edit sheet ───────────────────────────────────────────────────────────────

class _EditReviewSheet extends StatefulWidget {
  final ReviewModel review;
  final Future<bool> Function(int reviewId, double rating, String? text)? onSave;

  const _EditReviewSheet({required this.review, this.onSave});

  @override
  State<_EditReviewSheet> createState() => _EditReviewSheetState();
}

class _EditReviewSheetState extends State<_EditReviewSheet> {
  late double _rating;
  late TextEditingController _textCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating;
    _textCtrl = TextEditingController(text: widget.review.text ?? '');
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onSave?.call(
          widget.review.id,
          _rating,
          _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim(),
        ) ??
        false;
    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            Text('Изменить отзыв', style: AppTextStyles.headingMedium),
            const SizedBox(height: 16),
            // Звёзды
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = (i + 1).toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFFB800),
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ваш отзыв (необязательно)',
                filled: true,
                fillColor: AppColors.backgroundApp,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Сохранить',
                        style: AppTextStyles.labelBold
                            .copyWith(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
