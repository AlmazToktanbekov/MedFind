import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/notification_model.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _confirmDeleteAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить все?'),
        content: const Text('Все уведомления будут удалены без возможности восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationsProvider.notifier).deleteAll();
            },
            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        elevation: 0,
        title: Text('Уведомления', style: AppTextStyles.headingMedium),
        centerTitle: false,
        actions: [
          if (state.items.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'read_all') {
                  ref.read(notificationsProvider.notifier).markAllRead();
                } else if (value == 'delete_all') {
                  _confirmDeleteAll(context, ref);
                }
              },
              itemBuilder: (_) => [
                if (state.unreadCount > 0)
                  const PopupMenuItem(
                    value: 'read_all',
                    child: Text('Прочитать всё'),
                  ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Text('Удалить все', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationsProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = state.items[i];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            ref.read(notificationsProvider.notifier).delete(item.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                        ),
                        child: _NotificationCard(
                          item: item,
                          onTap: () {
                            if (!item.isRead) {
                              ref.read(notificationsProvider.notifier).markRead(item.id);
                            }
                            if (item.route != null) context.push(item.route!);
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.bell, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Нет уведомлений', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = _iconForType(item.type);
    final timeStr = DateFormat('dd.MM HH:mm').format(item.createdAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? const Color(0xFFF8F9FA) : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: item.isRead ? null : AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.labelBold.copyWith(
                            color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.body, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(timeStr, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (item.route != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconForType(String type) => switch (type) {
        'doctor_approved' => (PhosphorIconsFill.checkCircle, AppColors.success),
        'doctor_rejected' => (PhosphorIconsFill.xCircle, AppColors.error),
        'doctor_deactivated' => (PhosphorIconsFill.pauseCircle, AppColors.warning),
        'doctor_removed' => (PhosphorIconsFill.userMinus, AppColors.error),
        'profile_updated' => (PhosphorIconsFill.checkCircle, AppColors.success),
        'profile_update_rejected' => (PhosphorIconsFill.xCircle, AppColors.error),
        'clinic_update_request' => (PhosphorIconsFill.clockCounterClockwise, AppColors.primaryBlue),
        'new_review' => (PhosphorIconsFill.star, AppColors.warning),
        _ => (PhosphorIconsFill.bell, AppColors.textSecondary),
      };
}
