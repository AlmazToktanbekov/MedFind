import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../clinics/data/clinics_repository.dart';

// ─── Provider ──────────────────────────────────────────────────────────────

final _clinicsRepoProvider =
    Provider<ClinicsRepository>((_) => ClinicsRepository());

final _doctorRequestsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, clinicId) async {
  return ref.read(_clinicsRepoProvider).getDoctorRequests(clinicId);
});

final _doctorUpdateRequestsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, clinicId) async {
  return ref.read(_clinicsRepoProvider).getDoctorUpdateRequests(clinicId);
});

// ─── Screen ────────────────────────────────────────────────────────────────

class DoctorRequestsScreen extends ConsumerStatefulWidget {
  final int clinicId;
  final int initialTab;

  const DoctorRequestsScreen(
      {super.key, required this.clinicId, this.initialTab = 0});

  @override
  ConsumerState<DoctorRequestsScreen> createState() =>
      _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends ConsumerState<DoctorRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _action(
    Future<void> Function() fn,
    String successMsg,
  ) async {
    bool success = false;
    try {
      await fn();
      success = true;
    } catch (_) {}

    if (!mounted) return;
    // Always refresh both lists — even on 404 the state may have changed
    ref.invalidate(_doctorRequestsProvider(widget.clinicId));
    ref.invalidate(_doctorUpdateRequestsProvider(widget.clinicId));

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMsg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка. Попробуйте ещё раз.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(_clinicsRepoProvider);
    final requestsAsync =
        ref.watch(_doctorRequestsProvider(widget.clinicId));
    final updateRequestsAsync =
        ref.watch(_doctorUpdateRequestsProvider(widget.clinicId));

    final d = requestsAsync.valueOrNull;
    int len(String k) => (d?[k] as List<dynamic>?)?.length ?? 0;
    final counts = [
      len('pending'),
      len('active'),
      len('deactivated'),
      len('removed'),
      updateRequestsAsync.valueOrNull?.length ?? 0,
    ];
    const labels = ['Ожидают', 'Активные', 'Откл.', 'Удалённые', 'Обновления'];
    const accents = [
      AppColors.warning,
      AppColors.success,
      AppColors.textSecondary,
      AppColors.error,
      AppColors.primaryBlue,
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Управление врачами', style: AppTextStyles.headingMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: AppColors.backgroundApp,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: AppTextStyles.labelBold,
              unselectedLabelStyle: AppTextStyles.labelBold,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryBlue,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: const Color(0xFFE8EDF8),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                for (var i = 0; i < labels.length; i++)
                  _CountTab(label: labels[i], count: counts[i], accent: accents[i]),
              ],
            ),
          ),
        ),
      ),
      body: requestsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ошибка загрузки',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref
                    .invalidate(_doctorRequestsProvider(widget.clinicId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (data) {
          final updateRequestsAsync = ref.watch(_doctorUpdateRequestsProvider(widget.clinicId));
          final pending =
              (data['pending'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final active =
              (data['active'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final deactivated =
              (data['deactivated'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
                  [];
          final removed =
              (data['removed'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

          return TabBarView(
            controller: _tabs,
            children: [
              _DoctorList(
                doctors: pending,
                emptyText: 'Нет новых заявок',
                emptySubtitle:
                    'Когда врач выберет вашу клинику при регистрации, его заявка появится здесь',
                emptyIcon: PhosphorIconsRegular.userPlus,
                onCardTap: (doc) => _showDoctorProfile(
                  repo,
                  doc,
                  onApprove: () => _action(
                    () => repo.approveDoctor(widget.clinicId, doc['id'] as int),
                    'Врач подтверждён',
                  ),
                  onReject: () => _action(
                    () => repo.rejectDoctor(widget.clinicId, doc['id'] as int),
                    'Заявка отклонена',
                  ),
                ),
                actions: (_) => [],
              ),
              _DoctorList(
                doctors: active,
                emptyText: 'Нет активных врачей',
                emptySubtitle:
                    'Подтверждённые врачи будут показаны здесь и станут видны пациентам',
                emptyIcon: PhosphorIconsRegular.stethoscope,
                actions: (doc) => [
                  _ActionButton(
                    label: 'Деактивировать',
                    color: AppColors.warning,
                    icon: PhosphorIconsRegular.pauseCircle,
                    onTap: () => _action(
                      () => repo.deactivateDoctor(
                          widget.clinicId, doc['id'] as int),
                      'Врач деактивирован',
                    ),
                  ),
                  _ActionButton(
                    label: 'Удалить',
                    color: AppColors.error,
                    icon: PhosphorIconsRegular.trash,
                    onTap: () => _confirmRemove(repo, doc),
                  ),
                ],
              ),
              _DoctorList(
                doctors: deactivated,
                emptyText: 'Нет деактивированных врачей',
                emptySubtitle:
                    'Здесь будут врачи, которых вы временно скрыли от пациентов',
                emptyIcon: PhosphorIconsRegular.pauseCircle,
                actions: (doc) => [
                  _ActionButton(
                    label: 'Активировать',
                    color: AppColors.success,
                    icon: PhosphorIconsRegular.play,
                    onTap: () => _action(
                      () => repo.activateDoctor(
                          widget.clinicId, doc['id'] as int),
                      'Врач активирован',
                    ),
                  ),
                  _ActionButton(
                    label: 'Удалить',
                    color: AppColors.error,
                    icon: PhosphorIconsRegular.trash,
                    onTap: () => _confirmRemove(repo, doc),
                  ),
                ],
              ),
              _DoctorList(
                doctors: removed,
                emptyText: 'Нет удалённых врачей',
                emptySubtitle:
                    'Врачи, которых вы удалили из клиники, появятся здесь',
                emptyIcon: PhosphorIconsRegular.userMinus,
                actions: (_) => [],
              ),
              updateRequestsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(child: Text('Ошибка загрузки')),
                data: (updates) => _buildUpdateRequests(updates, repo),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUpdateRequests(
      List<Map<String, dynamic>> updates, ClinicsRepository repo) {
    if (updates.isEmpty) {
      return const _EmptyState(
        icon: PhosphorIconsRegular.pencilSimple,
        title: 'Нет запросов на обновление',
        subtitle:
            'Когда врач захочет изменить свой профиль, запрос на подтверждение появится здесь',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: updates.length,
      itemBuilder: (_, i) {
        final upd = updates[i];
        final name = upd['full_name_ru'] as String? ?? '—';
        final spec = upd['specialization_ru'] as String?;
        final updateId = upd['id'] as int;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                  _UpdatePhoto(photoUrl: upd['photo_url'] as String?),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.w600)),
                        if (spec != null)
                          Text(spec,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.primaryBlue)),
                        Text('Запросил обновление профиля',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Кнопка "Просмотреть изменения"
              GestureDetector(
                onTap: () => _showUpdateDetails(context, upd, repo),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.eye,
                          color: AppColors.primaryBlue, size: 14),
                      const SizedBox(width: 4),
                      Text('Просмотреть изменения',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ActionButton(
                    label: 'Подтвердить',
                    color: AppColors.success,
                    icon: PhosphorIconsRegular.checkCircle,
                    onTap: () => _action(
                      () => repo.approveDoctorUpdate(widget.clinicId, updateId),
                      'Изменения применены',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Отклонить',
                    color: AppColors.error,
                    icon: PhosphorIconsRegular.xCircle,
                    onTap: () => _action(
                      () => repo.rejectDoctorUpdate(widget.clinicId, updateId),
                      'Изменения отклонены',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUpdateDetails(BuildContext context,
      Map<String, dynamic> upd, ClinicsRepository repo) async {
    final updateId = upd['id'] as int;
    final doctorId = upd['doctor_id'] as int;
    final nav = Navigator.of(context);

    Map<String, dynamic>? doctor;
    try {
      doctor = await repo.getDoctorRaw(doctorId);
    } catch (_) {}

    if (!mounted) return;
    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: this.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateDetailsSheet(
        upd: upd,
        doctor: doctor,
        onApprove: () async {
          nav.pop();
          await _action(
            () => repo.approveDoctorUpdate(widget.clinicId, updateId),
            'Изменения применены',
          );
        },
        onReject: () async {
          nav.pop();
          await _action(
            () => repo.rejectDoctorUpdate(widget.clinicId, updateId),
            'Изменения отклонены',
          );
        },
      ),
    );
  }

  Future<void> _showDoctorProfile(
    ClinicsRepository repo,
    Map<String, dynamic> doc, {
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) async {
    final doctorId = doc['id'] as int;
    Map<String, dynamic>? fullDoc;
    try {
      fullDoc = await repo.getDoctorRaw(doctorId);
    } catch (_) {
      fullDoc = doc;
    }
    if (!mounted) return;
    showModalBottomSheet(
      // ignore: use_build_context_synchronously
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoctorProfileSheet(
        doctor: fullDoc ?? doc,
        onApprove: onApprove,
        onReject: onReject,
      ),
    );
  }

  void _confirmRemove(ClinicsRepository repo, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить врача?'),
        content: Text(
          'Врач ${doc['full_name_ru'] ?? ''} будет удалён из клиники. Он сможет подать заявку в другую клинику.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _action(
                () => repo.removeDoctor(widget.clinicId, doc['id'] as int),
                'Врач удалён',
              );
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Doctor list ───────────────────────────────────────────────────────────

// ─── Tab with count badge ──────────────────────────────────────────────────

class _CountTab extends StatelessWidget {
  final String label;
  final int count;
  final Color accent;
  const _CountTab(
      {required this.label, required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                    color: accent, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const _EmptyState({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primaryBlue.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoctorList extends StatelessWidget {
  final List<Map<String, dynamic>> doctors;
  final String emptyText;
  final String? emptySubtitle;
  final IconData emptyIcon;
  final List<_ActionButton> Function(Map<String, dynamic>) actions;
  final void Function(Map<String, dynamic>)? onCardTap;

  const _DoctorList({
    required this.doctors,
    required this.emptyText,
    required this.actions,
    this.emptySubtitle,
    this.emptyIcon = PhosphorIconsRegular.usersThree,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return _EmptyState(
          icon: emptyIcon, title: emptyText, subtitle: emptySubtitle);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: doctors.length,
      itemBuilder: (_, i) {
        final doc = doctors[i];
        return _DoctorCard(
          doctor: doc,
          actionButtons: actions(doc),
          onTap: onCardTap != null ? () => onCardTap!(doc) : null,
        );
      },
    );
  }
}

// ─── Doctor card ───────────────────────────────────────────────────────────

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final List<_ActionButton> actionButtons;
  final VoidCallback? onTap;

  const _DoctorCard({
    required this.doctor,
    required this.actionButtons,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = doctor['full_name_ru'] as String? ?? '';
    final spec = doctor['specialization_ru'] as String? ?? '';
    final phone = doctor['phone'] as String?;
    final exp = doctor['experience_years'] as int?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: onTap != null
            ? Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.stethoscope,
                    color: AppColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(spec,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primaryBlue)),
                  ],
                ),
              ),
            ],
          ),
          if (phone != null || exp != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (phone != null) ...[
                  const Icon(PhosphorIconsRegular.phone,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(phone, style: AppTextStyles.bodySmall),
                  const SizedBox(width: 16),
                ],
                if (exp != null) ...[
                  const Icon(PhosphorIconsRegular.certificate,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('$exp лет стажа', style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ],
          if (actionButtons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: actionButtons
                  .map((btn) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: btn,
                      ))
                  .toList(),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.btnGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsRegular.eye,
                      size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Посмотреть профиль',
                      style: AppTextStyles.labelBold
                          .copyWith(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    ));
  }
}

// ─── Action button ─────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Update photo avatar ────────────────────────────────────────────────────

class _UpdatePhoto extends StatelessWidget {
  final String? photoUrl;
  const _UpdatePhoto({this.photoUrl});

  String _resolveUrl(String url) => AppConstants.fixUrl(url);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        image: photoUrl != null
            ? DecorationImage(
                image: NetworkImage(_resolveUrl(photoUrl!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: photoUrl == null
          ? const Icon(PhosphorIconsRegular.pencilSimple,
              color: AppColors.warning, size: 22)
          : null,
    );
  }
}

// ─── Update details bottom sheet ───────────────────────────────────────────

class _UpdateDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> upd;
  final Map<String, dynamic>? doctor;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _UpdateDetailsSheet(
      {required this.upd,
      required this.doctor,
      required this.onApprove,
      required this.onReject});

  static const _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  String _resolveUrl(String url) => AppConstants.fixUrl(url);

  List<dynamic> _parseJson(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  // Returns value from upd if changed, else from doctor
  T? _val<T>(String key) {
    if (upd[key] != null) return upd[key] as T?;
    return doctor?[key] as T?;
  }

  bool _changed(String key) => upd[key] != null;

  @override
  Widget build(BuildContext context) {
    // Merge: update request fields take priority (they are the "new" values)
    final updContacts = _parseJson(upd['contacts_json'] as String?);
    final updServices = _parseJson(upd['services_json'] as String?);
    final updSchedules = _parseJson(upd['schedules_json'] as String?);

    // Full doctor data
    final docContacts = (doctor?['contacts'] as List<dynamic>?) ?? [];
    final docServices = (doctor?['services'] as List<dynamic>?) ?? [];
    final docSchedules = (doctor?['schedules'] as List<dynamic>?) ?? [];

    // Use update fields if present, else full doctor fields
    final contacts = updContacts.isNotEmpty ? updContacts : docContacts;
    final services = updServices.isNotEmpty ? updServices : docServices;
    final schedules = updSchedules.isNotEmpty ? updSchedules : docSchedules;

    final contactsChanged = updContacts.isNotEmpty;
    final servicesChanged = updServices.isNotEmpty;
    final schedulesChanged = updSchedules.isNotEmpty;

    final photoUrl = _val<String>('photo_url');
    final fullName = _val<String>('full_name_ru') ?? '—';
    final spec = _val<String>('specialization_ru');
    final hasOnline = _val<bool>('has_online') ?? false;
    final hasOffline = _val<bool>('has_offline') ?? false;
    final onlinePrice = _val('online_price');
    final offlinePrice = _val('offline_price');
    final availableSchedules =
        schedules.where((s) => s['is_available'] == true).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A1565C0),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gradient header ──────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF2979FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Photo + name
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2),
                          ),
                          child: photoUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _resolveUrl(photoUrl),
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => const Icon(
                                        PhosphorIconsRegular.userCircle,
                                        color: Colors.white,
                                        size: 36),
                                  ),
                                )
                              : const Icon(PhosphorIconsRegular.userCircle,
                                  color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (_changed('full_name_ru'))
                                    _ChangedBadge(),
                                ],
                              ),
                              if (spec != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        spec,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (_changed('specialization_ru'))
                                      _ChangedBadge(),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tag row
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.pencilSimple,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Запрос на обновление профиля',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Content ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Основная информация ──────────────────────
                    _SectionHeader(
                        icon: PhosphorIconsRegular.userCircle,
                        label: 'Основная информация'),
                    const SizedBox(height: 8),
                    _InfoCard(children: [
                      if (_val<String>('education') != null)
                        _InfoRow(
                          icon: PhosphorIconsRegular.graduationCap,
                          label: 'Образование',
                          value: _val<String>('education')!,
                          changed: _changed('education'),
                        ),
                      if (_val<int>('experience_years') != null) ...[
                        if (_val<String>('education') != null) _Divider(),
                        _InfoRow(
                          icon: PhosphorIconsRegular.clock,
                          label: 'Стаж',
                          value: '${_val<int>('experience_years')} лет',
                          changed: _changed('experience_years'),
                        ),
                      ],
                      if (_val<String>('consultation_language') != null) ...[
                        if (_val<String>('education') != null ||
                            _val<int>('experience_years') != null)
                          _Divider(),
                        _InfoRow(
                          icon: PhosphorIconsRegular.translate,
                          label: 'Язык',
                          value: _val<String>('consultation_language')!,
                          changed: _changed('consultation_language'),
                        ),
                      ],
                      if (_val<String>('bio_ru') != null) ...[
                        if (_val<String>('education') != null ||
                            _val<int>('experience_years') != null ||
                            _val<String>('consultation_language') != null)
                          _Divider(),
                        _InfoRow(
                          icon: PhosphorIconsRegular.info,
                          label: 'О себе',
                          value: _val<String>('bio_ru')!,
                          changed: _changed('bio_ru'),
                        ),
                      ],
                      if (_val<String>('phone') != null) ...[
                        if (_val<String>('education') != null ||
                            _val<int>('experience_years') != null ||
                            _val<String>('consultation_language') != null ||
                            _val<String>('bio_ru') != null)
                          _Divider(),
                        _InfoRow(
                          icon: PhosphorIconsRegular.phone,
                          label: 'Телефон',
                          value: _val<String>('phone')!,
                          changed: _changed('phone'),
                        ),
                      ],
                    ]),

                    // ── Формат консультации ───────────────────────
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _SectionHeader(
                            icon: PhosphorIconsRegular.stethoscope,
                            label: 'Формат консультации'),
                        if (_changed('has_online') ||
                            _changed('has_offline') ||
                            _changed('online_price') ||
                            _changed('offline_price'))
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _ChangedBadge(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (hasOffline)
                          Expanded(
                            child: _FormatCard(
                              icon: PhosphorIconsRegular.hospital,
                              label: 'Очный',
                              price: offlinePrice != null
                                  ? '${(offlinePrice as num).toInt()} сом'
                                  : null,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        if (hasOffline && hasOnline) const SizedBox(width: 10),
                        if (hasOnline)
                          Expanded(
                            child: _FormatCard(
                              icon: PhosphorIconsRegular.videoCamera,
                              label: 'Онлайн',
                              price: onlinePrice != null
                                  ? '${(onlinePrice as num).toInt()} сом'
                                  : null,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        if (!hasOffline && !hasOnline)
                          Text('—',
                              style: AppTextStyles.bodyLarge
                                  .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),

                    // ── Контакты ─────────────────────────────────
                    if (contacts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _SectionHeader(
                              icon: PhosphorIconsRegular.phone,
                              label: 'Контакты'),
                          if (contactsChanged)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _ChangedBadge(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoCard(
                        children: contacts.asMap().entries.map((entry) {
                          final i = entry.key;
                          final c = entry.value as Map<String, dynamic>;
                          final type = c['type'] as String;
                          final value = c['value'] as String;
                          final (icon, color, label) = switch (type) {
                            'whatsapp' => (
                                PhosphorIconsRegular.whatsappLogo,
                                const Color(0xFF25D366),
                                'WhatsApp'
                              ),
                            'telegram' => (
                                PhosphorIconsRegular.telegramLogo,
                                const Color(0xFF0088CC),
                                'Telegram'
                              ),
                            'instagram' => (
                                PhosphorIconsRegular.instagramLogo,
                                const Color(0xFFE1306C),
                                'Instagram'
                              ),
                            _ => (
                                PhosphorIconsRegular.phone,
                                AppColors.primaryBlue,
                                'Телефон'
                              ),
                          };
                          return Column(
                            children: [
                              if (i > 0) _Divider(),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child:
                                          Icon(icon, color: color, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(label,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                    color:
                                                        AppColors.textSecondary)),
                                        Text(value,
                                            style: AppTextStyles.labelBold),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],

                    // ── Услуги ────────────────────────────────────
                    if (services.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _SectionHeader(
                              icon: PhosphorIconsRegular.listBullets,
                              label: 'Услуги'),
                          if (servicesChanged)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _ChangedBadge(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoCard(
                        children: services.asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value as Map<String, dynamic>;
                          final sName = s['name_ru'] as String? ?? '';
                          final price = s['price'];
                          return Column(
                            children: [
                              if (i > 0) _Divider(),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(sName,
                                          style: AppTextStyles.labelBold),
                                    ),
                                    if (price != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${(price as num).toInt()} сом',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  color: AppColors.primaryBlue,
                                                  fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],

                    // ── График приёма ─────────────────────────────
                    if (availableSchedules.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _SectionHeader(
                              icon: PhosphorIconsRegular.calendarBlank,
                              label: 'График приёма'),
                          if (schedulesChanged)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _ChangedBadge(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSchedules.map((s) {
                          final day = s['day_of_week'] as int;
                          final start = s['start_time'] as String;
                          final end = s['end_time'] as String;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primaryBlue
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _days[day],
                                  style: AppTextStyles.labelBold
                                      .copyWith(color: AppColors.primaryBlue),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$start–$end',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // ── Кнопки действий ──────────────────────────
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onReject,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIconsRegular.xCircle,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Отклонить',
                                      style: AppTextStyles.labelBold
                                          .copyWith(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: onApprove,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1565C0),
                                    Color(0xFF2979FF)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIconsRegular.checkCircle,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Подтвердить',
                                      style: AppTextStyles.labelBold
                                          .copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Doctor profile bottom sheet ───────────────────────────────────────────

class _DoctorProfileSheet extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DoctorProfileSheet({
    required this.doctor,
    required this.onApprove,
    required this.onReject,
  });

  static const _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  String _resolveUrl(String url) => AppConstants.fixUrl(url);

  @override
  Widget build(BuildContext context) {
    final photoUrl = doctor['photo_url'] as String?;
    final fullName = doctor['full_name_ru'] as String? ?? '—';
    final spec = doctor['specialization_ru'] as String?;
    final education = doctor['education'] as String?;
    final expYears = doctor['experience_years'] as int?;
    final phone = doctor['phone'] as String?;
    final hasOnline = doctor['has_online'] as bool? ?? false;
    final hasOffline = doctor['has_offline'] as bool? ?? false;
    final onlinePrice = doctor['online_price'];
    final offlinePrice = doctor['offline_price'];
    final contacts = (doctor['contacts'] as List<dynamic>?) ?? [];
    final services = (doctor['services'] as List<dynamic>?) ?? [];
    final schedules = (doctor['schedules'] as List<dynamic>?) ?? [];
    final availableSchedules =
        schedules.where((s) => s['is_available'] == true).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A1565C0),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Gradient header ──────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF2979FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 2),
                            ),
                            child: photoUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: _resolveUrl(photoUrl),
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => const Icon(
                                          PhosphorIconsRegular.userCircle,
                                          color: Colors.white,
                                          size: 36),
                                    ),
                                  )
                                : const Icon(PhosphorIconsRegular.userCircle,
                                    color: Colors.white, size: 36),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (spec != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      spec,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Основная информация
                      _SectionHeader(
                          icon: PhosphorIconsRegular.userCircle,
                          label: 'Основная информация'),
                      const SizedBox(height: 8),
                      _InfoCard(children: [
                        if (education != null)
                          _InfoRow(
                            icon: PhosphorIconsRegular.graduationCap,
                            label: 'Образование',
                            value: education,
                          ),
                        if (expYears != null) ...[
                          if (education != null) _Divider(),
                          _InfoRow(
                            icon: PhosphorIconsRegular.clock,
                            label: 'Стаж',
                            value: '$expYears лет',
                          ),
                        ],
                        if (phone != null) ...[
                          if (education != null || expYears != null) _Divider(),
                          _InfoRow(
                            icon: PhosphorIconsRegular.phone,
                            label: 'Телефон',
                            value: phone,
                          ),
                        ],
                      ]),

                      // Формат консультации
                      const SizedBox(height: 14),
                      _SectionHeader(
                          icon: PhosphorIconsRegular.stethoscope,
                          label: 'Формат консультации'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (hasOffline)
                            Expanded(
                              child: _FormatCard(
                                icon: PhosphorIconsRegular.hospital,
                                label: 'Очный',
                                price: offlinePrice != null
                                    ? '${(offlinePrice as num).toInt()} сом'
                                    : null,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          if (hasOffline && hasOnline) const SizedBox(width: 10),
                          if (hasOnline)
                            Expanded(
                              child: _FormatCard(
                                icon: PhosphorIconsRegular.videoCamera,
                                label: 'Онлайн',
                                price: onlinePrice != null
                                    ? '${(onlinePrice as num).toInt()} сом'
                                    : null,
                                color: AppColors.accentBlue,
                              ),
                            ),
                          if (!hasOffline && !hasOnline)
                            Text('—',
                                style: AppTextStyles.bodyLarge
                                    .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),

                      // Контакты
                      if (contacts.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _SectionHeader(
                            icon: PhosphorIconsRegular.phone,
                            label: 'Контакты'),
                        const SizedBox(height: 8),
                        _InfoCard(
                          children: contacts.asMap().entries.map((entry) {
                            final i = entry.key;
                            final c = entry.value as Map<String, dynamic>;
                            final type = c['type'] as String;
                            final value = c['value'] as String;
                            final (icon, color, label) = switch (type) {
                              'whatsapp' => (PhosphorIconsRegular.whatsappLogo,
                                  const Color(0xFF25D366), 'WhatsApp'),
                              'telegram' => (PhosphorIconsRegular.telegramLogo,
                                  const Color(0xFF0088CC), 'Telegram'),
                              'instagram' => (PhosphorIconsRegular.instagramLogo,
                                  const Color(0xFFE1306C), 'Instagram'),
                              _ => (PhosphorIconsRegular.phone,
                                  AppColors.primaryBlue, 'Телефон'),
                            };
                            return Column(children: [
                              if (i > 0) _Divider(),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(icon, color: color, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(label,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  color:
                                                      AppColors.textSecondary)),
                                      Text(value,
                                          style: AppTextStyles.labelBold),
                                    ],
                                  ),
                                ]),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ],

                      // Услуги
                      if (services.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _SectionHeader(
                            icon: PhosphorIconsRegular.listBullets,
                            label: 'Услуги'),
                        const SizedBox(height: 8),
                        _InfoCard(
                          children: services.asMap().entries.map((entry) {
                            final i = entry.key;
                            final s = entry.value as Map<String, dynamic>;
                            final sName = s['name_ru'] as String? ?? '';
                            final price = s['price'];
                            return Column(children: [
                              if (i > 0) _Divider(),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: Text(sName,
                                            style: AppTextStyles.labelBold)),
                                    if (price != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${(price as num).toInt()} сом',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                  color: AppColors.primaryBlue,
                                                  fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ],

                      // График приёма
                      if (availableSchedules.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _SectionHeader(
                            icon: PhosphorIconsRegular.calendarBlank,
                            label: 'График приёма'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableSchedules.map((s) {
                            final day = s['day_of_week'] as int;
                            final start = s['start_time'] as String;
                            final end = s['end_time'] as String;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Column(children: [
                                Text(_days[day],
                                    style: AppTextStyles.labelBold
                                        .copyWith(color: AppColors.primaryBlue)),
                                const SizedBox(height: 2),
                                Text('$start–$end',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary)),
                              ]),
                            );
                          }).toList(),
                        ),
                      ],

                      // Кнопки действий
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              onReject();
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.error
                                        .withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIconsRegular.xCircle,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Отклонить',
                                      style: AppTextStyles.labelBold
                                          .copyWith(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              onApprove();
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1565C0),
                                    Color(0xFF2979FF)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIconsRegular.checkCircle,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Подтвердить',
                                      style: AppTextStyles.labelBold
                                          .copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.labelBold
                .copyWith(color: AppColors.textPrimary, fontSize: 15)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1565C0),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool changed;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.changed = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    if (changed) ...[
                      const SizedBox(width: 6),
                      _ChangedBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Text(
        'изменено',
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? price;
  final Color color;
  const _FormatCard(
      {required this.icon,
      required this.label,
      required this.price,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.labelBold.copyWith(color: color)),
              if (price != null)
                Text(price!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: color.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1, thickness: 1, color: const Color(0xFFE8EEF8));
  }
}
