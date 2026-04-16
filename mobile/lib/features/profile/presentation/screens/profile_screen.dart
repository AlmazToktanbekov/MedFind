import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/search/providers/search_provider.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final favorites = ref.watch(favoritesProvider);
    final searchState = ref.watch(searchProvider);
    final locale = ref.watch(localeProvider);

    final doctorCount = favorites.where((k) => k.startsWith('doctor:')).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: SafeArea(
        child: profile.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 24),

                  // ── Аватар + имя + телефон ───────────────────────────
                  _AvatarSection(profile: profile),

                  const SizedBox(height: 28),

                  // ── Избранное ────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _NavRow(
                        icon: PhosphorIconsRegular.heart,
                        iconColor: const Color(0xFFE53935),
                        title: 'Избранные врачи',
                        badge: doctorCount > 0 ? '$doctorCount' : null,
                        onTap: () => context.push('/main/favorites'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── История поиска ───────────────────────────────────
                  if (searchState.history.isNotEmpty) ...[
                    _HistorySection(history: searchState.history),
                    const SizedBox(height: 16),
                  ],

                  // ── Язык приложения ──────────────────────────────────
                  _SectionCard(
                    children: [
                      _LanguageRow(
                        current: locale,
                        onChanged: (loc) =>
                            ref.read(localeProvider.notifier).setLocale(loc),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Кнопка выйти ─────────────────────────────────────
                  _LogoutButton(
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}

// ─── Аватар + имя ──────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final ProfileState profile;

  const _AvatarSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: AppTextStyles.headingMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (profile.phone != null) ...[
                const SizedBox(height: 4),
                Text(
                  profile.phone!,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Карточка-секция ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

// ─── Строка навигации ──────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? badge;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    this.iconColor,
    required this.title,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primaryBlue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyLarge),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── История поиска ────────────────────────────────────────────────────────

class _HistorySection extends ConsumerWidget {
  final List<String> history;

  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('История поиска', style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                TextButton(
                  onPressed: () =>
                      ref.read(searchProvider.notifier).clearHistory(),
                  child: Text(
                    'Очистить',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          ...history.take(5).map(
                (q) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(
                        PhosphorIconsRegular.clockCounterClockwise,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(q, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Выбор языка ───────────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  final Locale current;
  final ValueChanged<Locale> onChanged;

  const _LanguageRow({required this.current, required this.onChanged});

  static const _languages = [
    (Locale('ru'), 'Русский', 'RU'),
    (Locale('ky'), 'Кыргызча', 'KG'),
    (Locale('en'), 'English', 'EN'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              PhosphorIconsRegular.globe,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Язык приложения', style: AppTextStyles.bodyLarge),
          ),
          DropdownButton<Locale>(
            value: current,
            underline: const SizedBox.shrink(),
            icon: const Icon(
              PhosphorIconsRegular.caretDown,
              size: 16,
              color: AppColors.textSecondary,
            ),
            style: AppTextStyles.labelBold,
            items: _languages
                .map(
                  (t) => DropdownMenuItem(
                    value: t.$1,
                    child: Text(t.$3),
                  ),
                )
                .toList(),
            onChanged: (loc) {
              if (loc != null) onChanged(loc);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Кнопка выйти ──────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              PhosphorIconsRegular.signOut,
              color: Color(0xFFE53935),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Выйти',
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFFE53935),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
