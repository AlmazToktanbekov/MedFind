import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:medfind/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/provider/providers/doctor_setup_provider.dart';
import '../../../../features/search/providers/search_provider.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../clinics/presentation/screens/clinic_manage_screen.dart' show myClinicProvider;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    final favorites = ref.watch(favoritesProvider);
    final searchState = ref.watch(searchProvider);
    final locale = ref.watch(localeProvider);
    final myDoctorAsync = ref.watch(myDoctorProvider);
    final role = profile.role;

    final doctorCount = favorites.where((k) => k.startsWith('doctor:')).length;
    final clinicCount = favorites.where((k) => k.startsWith('clinic:')).length;
    final pharmacyCount = favorites
        .where((k) => k.startsWith('pharmacy:'))
        .length;

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
                  _AvatarSection(profile: profile, role: role),

                  const SizedBox(height: 28),

                  // ── Статус врача (если зарегистрирован) ─────────────
                  myDoctorAsync.when(
                    data: (doctor) => doctor != null
                        ? _DoctorStatusSection(doctor: doctor)
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),

                  if (myDoctorAsync.value != null) const SizedBox(height: 16),

                  // ── Управление аккаунтом (провайдеры) ───────────────
                  if (role == 'doctor' ||
                      role == 'clinic' ||
                      role == 'pharmacy') ...[
                    _ProviderManagementSection(role: role!),
                    const SizedBox(height: 16),
                  ],

                  // ── Избранное ────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _NavRow(
                        icon: PhosphorIconsRegular.heart,
                        iconColor: const Color.fromARGB(255, 255, 0, 0),
                        title: l.profileFavorites,
                        badge: doctorCount > 0 ? '$doctorCount' : null,
                        onTap: () => context.push('/main/favorites'),
                      ),
                      if (clinicCount > 0)
                        _NavRow(
                          icon: PhosphorIconsRegular.hospital,
                          iconColor: AppColors.accentBlue,
                          title: l.profileFavoriteClinics,
                          badge: '$clinicCount',
                          onTap: () => context.push('/main/clinics'),
                        ),
                      if (pharmacyCount > 0)
                        _NavRow(
                          icon: PhosphorIconsRegular.pill,
                          iconColor: AppColors.success,
                          title: l.profileFavoritePharmacies,
                          badge: '$pharmacyCount',
                          onTap: () => context.push('/main/pharmacies'),
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
  final String? role;

  const _AvatarSection({required this.profile, this.role});

  @override
  Widget build(BuildContext context) {
    final isPatient = role == 'patient' || role == null;
    return Row(
      children: [
        GestureDetector(
          onTap: isPatient ? () => context.push('/main/edit-profile') : null,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                child: profile.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          AppConstants.fixUrl(profile.photoUrl!),
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, e, _) => Center(
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
                      )
                    : Center(
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
              if (isPatient)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.pencilSimple,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
            ],
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
              if (isPatient) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => context.push('/main/edit-profile'),
                  child: Text(
                    'Редактировать профиль',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (profile.phone != null) ...[
                const SizedBox(height: 4),
                Text(
                  profile.phone!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
                color: (iconColor ?? AppColors.primaryBlue).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTextStyles.bodyLarge)),
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
    final l = AppLocalizations.of(context);
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
                Text(
                  l.profileSearchHistory,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(searchProvider.notifier).clearHistory(),
                  child: Text(
                    l.profileClear,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...history
              .take(5)
              .map(
                (q) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
            child: Text(AppLocalizations.of(context).profileAppLanguage,
                style: AppTextStyles.bodyLarge),
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
                .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$3)))
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

// ─── Статус врача ──────────────────────────────────────────────────────────

class _DoctorStatusSection extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const _DoctorStatusSection({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final status = doctor['status'] as String? ?? 'active';
    final clinicName = doctor['clinic_name'] as String?;
    final hasPendingUpdate = doctor['has_pending_update'] == true;

    if (status == 'removed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error, width: 1.5),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.warningCircle,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Вы не отображаетесь в поиске',
                  style: AppTextStyles.labelBold.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Клиника удалила вас из списка врачей. Выберите новую клинику, чтобы снова стать видимым пациентам.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/provider/setup'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Выбрать новую клинику',
                  style: AppTextStyles.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Active / pending / deactivated — show info card
    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'active':
        statusColor = AppColors.success;
        statusText = 'Активен';
        statusIcon = PhosphorIconsRegular.checkCircle;
      case 'deactivated':
        statusColor = AppColors.warning;
        statusText = 'Деактивирован клиникой';
        statusIcon = PhosphorIconsRegular.pauseCircle;
      case 'rejected':
        statusColor = AppColors.error;
        statusText = 'Отклонён';
        statusIcon = PhosphorIconsRegular.xCircle;
      default:
        statusColor = AppColors.primaryBlue;
        statusText = 'На проверке';
        statusIcon = PhosphorIconsRegular.clock;
    }

    return _SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIconsRegular.stethoscope,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Профиль врача', style: AppTextStyles.bodyLarge),
                    if (clinicName != null)
                      Text(
                        clinicName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasPendingUpdate)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsRegular.clock, color: AppColors.warning, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Изменения на проверке у клиники',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Управление аккаунтом провайдера ──────────────────────────────────────

class _ProviderManagementSection extends ConsumerWidget {
  final String role;

  const _ProviderManagementSection({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (role == 'clinic') return _ClinicManagement(ref: ref);

    final (
      IconData icon,
      String title,
      String subtitle,
      String route,
      Color color,
    ) = switch (role) {
      'doctor' => (
        PhosphorIconsRegular.stethoscope,
        'Мой профиль врача',
        'Редактировать данные, выбрать клинику',
        '/provider/doctor-edit',
        AppColors.primaryBlue,
      ),
      'pharmacy' => (
        PhosphorIconsRegular.pill,
        'Управление аптекой',
        'Компания, филиалы, профиль',
        '/provider/pharmacy/manage',
        AppColors.warning,
      ),
      _ => (
        PhosphorIconsRegular.userGear,
        'Мой аккаунт',
        '',
        '/main',
        AppColors.primaryBlue,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Управление аккаунтом'),
        _NavCard(
          icon: icon,
          color: color,
          title: title,
          subtitle: subtitle,
          onTap: () => context.push(route),
        ),
      ],
    );
  }
}

// Inline-разделы управления клиникой (вместо одной кнопки «Управление клиникой»)
class _ClinicManagement extends StatelessWidget {
  final WidgetRef ref;
  const _ClinicManagement({required this.ref});

  @override
  Widget build(BuildContext context) {
    final clinicAsync = ref.watch(myClinicProvider);
    final clinic = clinicAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Управление клиникой'),
        if (clinic == null)
          _NavCard(
            icon: PhosphorIconsRegular.hospital,
            color: AppColors.accentBlue,
            title: clinicAsync.isLoading ? 'Загрузка…' : 'Зарегистрировать клинику',
            subtitle: clinicAsync.isLoading ? '' : 'Создайте профиль клиники',
            onTap: () => context.push('/provider/clinic-intro'),
          )
        else ...[
          _NavCard(
            icon: PhosphorIconsRegular.pencilSimple,
            color: AppColors.accentBlue,
            title: 'Редактировать профиль',
            subtitle: 'Информация, контакты, фото',
            onTap: () => context.push('/clinic/${clinic.id}/edit'),
          ),
          const SizedBox(height: 10),
          _NavCard(
            icon: PhosphorIconsRegular.userList,
            color: AppColors.primaryBlue,
            title: 'Врачи клиники',
            subtitle: 'Список подтверждённых врачей',
            onTap: () => context.push('/clinic/${clinic.id}/doctors'),
          ),
          const SizedBox(height: 10),
          _NavCard(
            icon: PhosphorIconsRegular.clockCounterClockwise,
            color: AppColors.warning,
            title: 'Заявки врачей',
            subtitle: 'Ожидают / активны / отклонены / обновления',
            onTap: () => context.push('/clinic/${clinic.id}/doctor-requests'),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
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
              AppLocalizations.of(context).profileLogout,
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
