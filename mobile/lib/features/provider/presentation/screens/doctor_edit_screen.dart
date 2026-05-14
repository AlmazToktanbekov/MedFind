import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/doctor_setup_provider.dart';
import '../../data/provider_repository.dart';

// ─── Screen ────────────────────────────────────────────────────────────────

class DoctorEditScreen extends ConsumerStatefulWidget {
  const DoctorEditScreen({super.key});

  @override
  ConsumerState<DoctorEditScreen> createState() => _DoctorEditScreenState();
}

class _DoctorEditScreenState extends ConsumerState<DoctorEditScreen> {
  final _repo = ProviderRepository();

  // Scalar field controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _onlinePriceCtrl = TextEditingController();
  final _offlinePriceCtrl = TextEditingController();
  final _langCtrl = TextEditingController();
  final _expCtrl = TextEditingController();

  // WhatsApp, Telegram, Instagram
  final _waCtrl = TextEditingController();
  final _tgCtrl = TextEditingController();
  final _igCtrl = TextEditingController();

  String? _specialization;
  bool _hasOnline = false;
  bool _hasOffline = true;
  String? _photoUrl;
  String? _coverPhotoUrl;
  bool _isCoverUploading = false;

  // Clinic
  String? _currentClinicName;
  int? _selectedNewClinicId;
  String? _selectedNewClinicName;
  final _clinicSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _clinicResults = [];
  bool _isClinicSearching = false;
  bool _isApplyingClinic = false;

  List<ServiceEntry> _services = [];
  List<ScheduleEntry> _schedules = List.generate(
    7,
    (i) => ScheduleEntry(dayOfWeek: i),
  );

  bool _initialized = false;
  bool _isLoading = false;
  bool _isPhotoUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final doctorAsync = ref.read(myDoctorProvider);
      if (doctorAsync.hasValue && doctorAsync.value == null) {
        context.replace('/provider/setup');
        return;
      }
      _initFromProvider();
    });
  }

  void _initFromProvider() {
    if (_initialized) return;
    final doctorAsync = ref.read(myDoctorProvider);
    final doctor = doctorAsync.value;
    if (doctor == null) return;
    _applyDoctorData(doctor);
  }

  void _applyDoctorData(Map<String, dynamic> d) {
    _currentClinicName = d['clinic_name'] as String?;
    _nameCtrl.text = d['full_name_ru'] ?? '';
    _phoneCtrl.text = d['phone'] ?? '';
    _bioCtrl.text = d['bio_ru'] ?? '';
    _educationCtrl.text = d['education'] ?? '';
    _langCtrl.text = d['consultation_language'] ?? '';
    _expCtrl.text = d['experience_years']?.toString() ?? '';
    final onlinePrice = d['online_price'];
    _onlinePriceCtrl.text = onlinePrice != null ? (onlinePrice as num).toInt().toString() : '';
    final offlinePrice = d['offline_price'];
    _offlinePriceCtrl.text = offlinePrice != null ? (offlinePrice as num).toInt().toString() : '';
    _specialization = d['specialization_ru'] as String?;
    _hasOnline = d['has_online'] as bool? ?? false;
    _hasOffline = d['has_offline'] as bool? ?? true;
    _photoUrl = d['photo_url'] as String?;
    _coverPhotoUrl = d['cover_photo_url'] as String?;

    // Contacts
    final contacts = d['contacts'] as List<dynamic>? ?? [];
    for (final c in contacts) {
      final type = c['type'] as String;
      final value = c['value'] as String;
      if (type == 'whatsapp') _waCtrl.text = value;
      if (type == 'telegram') _tgCtrl.text = value;
      if (type == 'instagram') _igCtrl.text = value;
    }

    // Services
    final services = d['services'] as List<dynamic>? ?? [];
    _services = services.map((s) {
      return ServiceEntry(
        name: s['name_ru'] as String? ?? '',
        price: s['price']?.toString() ?? '',
      );
    }).toList();

    // Schedules
    final schedules = d['schedules'] as List<dynamic>? ?? [];
    if (schedules.isNotEmpty) {
      final map = <int, ScheduleEntry>{};
      for (final s in schedules) {
        final day = s['day_of_week'] as int;
        final start = _parseTime(s['start_time'] as String? ?? '09:00');
        final end = _parseTime(s['end_time'] as String? ?? '18:00');
        final avail = s['is_available'] as bool? ?? true;
        map[day] = ScheduleEntry(
          dayOfWeek: day,
          isAvailable: avail,
          startTime: start,
          endTime: end,
        );
      }
      _schedules = List.generate(7, (i) => map[i] ?? ScheduleEntry(dayOfWeek: i));
    }

    _initialized = true;
    setState(() {});
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _bioCtrl, _educationCtrl, _langCtrl,
      _expCtrl, _onlinePriceCtrl, _offlinePriceCtrl,
      _waCtrl, _tgCtrl, _igCtrl, _clinicSearchCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _searchClinics(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _clinicResults = []);
      return;
    }
    setState(() => _isClinicSearching = true);
    try {
      final results = await _repo.searchClinics(query);
      setState(() => _clinicResults = results);
    } catch (_) {
    } finally {
      setState(() => _isClinicSearching = false);
    }
  }

  Future<void> _applyNewClinic() async {
    if (_selectedNewClinicId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сменить клинику?'),
        content: Text(
          'Вы подадите заявку в «$_selectedNewClinicName». Ваш статус изменится на «На проверке» до подтверждения новой клиникой.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Подать заявку',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isApplyingClinic = true);
    try {
      await _repo.applyClinic(_selectedNewClinicId!);
      if (mounted) {
        ref.invalidate(myDoctorProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заявка подана в «$_selectedNewClinicName»'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/provider/pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplyingClinic = false);
    }
  }

  Future<void> _pickPhoto() async {
    final path = await _repo.pickImagePath();
    if (path == null) return;
    setState(() => _isPhotoUploading = true);
    try {
      final url = await _repo.uploadPhoto(path);
      setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки фото')),
        );
      }
    } finally {
      setState(() => _isPhotoUploading = false);
    }
  }

  Future<void> _pickCoverPhoto() async {
    final path = await _repo.pickImagePath();
    if (path == null) return;
    setState(() => _isCoverUploading = true);
    try {
      final url = await _repo.uploadPhoto(path);
      setState(() => _coverPhotoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки фона')),
        );
      }
    } finally {
      setState(() => _isCoverUploading = false);
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите ФИО')),
      );
      return;
    }
    if (_specialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите специализацию')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final contacts = <Map<String, String>>[];
      if (_waCtrl.text.trim().isNotEmpty) {
        contacts.add({'type': 'whatsapp', 'value': _waCtrl.text.trim()});
      }
      if (_tgCtrl.text.trim().isNotEmpty) {
        contacts.add({'type': 'telegram', 'value': _tgCtrl.text.trim()});
      }
      if (_igCtrl.text.trim().isNotEmpty) {
        contacts.add({'type': 'instagram', 'value': _igCtrl.text.trim()});
      }
      if (_phoneCtrl.text.trim().isNotEmpty) {
        contacts.add({'type': 'phone', 'value': _phoneCtrl.text.trim()});
      }

      final services = _services
          .where((s) => s.name.trim().isNotEmpty)
          .map((s) => {
                'name_ru': s.name.trim(),
                if (s.price.isNotEmpty)
                  'price': double.tryParse(s.price),
              })
          .toList();

      final schedules = _schedules
          .map((s) => {
                'day_of_week': s.dayOfWeek,
                'start_time': s.startStr,
                'end_time': s.endStr,
                'is_available': s.isAvailable,
              })
          .toList();

      await _repo.requestProfileUpdate({
        'full_name_ru': _nameCtrl.text.trim(),
        'specialization_ru': _specialization,
        'bio_ru': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'education': _educationCtrl.text.trim().isEmpty ? null : _educationCtrl.text.trim(),
        'consultation_language': _langCtrl.text.trim().isEmpty ? null : _langCtrl.text.trim(),
        'experience_years': int.tryParse(_expCtrl.text.trim()),
        'has_online': _hasOnline,
        'has_offline': _hasOffline,
        'online_price': double.tryParse(_onlinePriceCtrl.text.trim()),
        'offline_price': double.tryParse(_offlinePriceCtrl.text.trim()),
        if (_photoUrl != null) 'photo_url': _photoUrl,
        if (_coverPhotoUrl != null) 'cover_photo_url': _coverPhotoUrl,
        'contacts': contacts,
        'services': services,
        'schedules': schedules,
      });

      if (mounted) {
        ref.invalidate(myDoctorProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запрос отправлен — клиника получит уведомление'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(myDoctorProvider);

    doctorAsync.whenData((d) {
      if (d != null && !_initialized) _applyDoctorData(d);
    });

    final hasPending = doctorAsync.value?['has_pending_update'] == true;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Редактировать профиль', style: AppTextStyles.headingMedium),
      ),
      body: doctorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Ошибка загрузки. Проверьте подключение.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(myDoctorProvider),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
        data: (doctor) {
          if (doctor == null) {
            // Профиль ещё не создан — перенаправляем на регистрацию
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.replace('/provider/setup');
            });
            return const Center(child: CircularProgressIndicator());
          }
          final status = doctor['status'] as String?;
          return _buildForm(hasPending, status: status);
        },
      ),
    );
  }

  Widget _buildForm(bool hasPending, {String? status}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (status == 'removed') const _RemovedBanner(),
        if (hasPending) _PendingBanner(onCancel: _cancelUpdate),

        _Section(
          title: 'Основная информация',
          icon: PhosphorIconsRegular.user,
          children: [
            _PhotoPicker(
              photoUrl: _photoUrl,
              isLoading: _isPhotoUploading,
              onTap: _pickPhoto,
            ),
            const SizedBox(height: 12),
            _CoverPhotoPicker(
              coverPhotoUrl: _coverPhotoUrl,
              isLoading: _isCoverUploading,
              onTap: _pickCoverPhoto,
            ),
            const SizedBox(height: 16),
            _Field(label: 'ФИО *', controller: _nameCtrl),
            const SizedBox(height: 12),
            _Field(
              label: 'Рабочий телефон',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 13,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d]'))],
            ),
          ],
        ),

        _Section(
          title: 'Специализация и формат',
          icon: PhosphorIconsRegular.stethoscope,
          children: [
            _DropdownField(
              label: 'Специализация *',
              value: _specialization,
              items: AppConstants.specializations,
              onChanged: (v) => setState(() => _specialization = v),
            ),
            const SizedBox(height: 12),
            _CheckRow(
              label: 'Очный приём',
              value: _hasOffline,
              onChanged: (v) => setState(() => _hasOffline = v),
            ),
            if (_hasOffline) ...[
              const SizedBox(height: 8),
              _FreeCheckRow(
                isFree: _offlinePriceCtrl.text.trim() == '0',
                onChanged: (free) => setState(() {
                  _offlinePriceCtrl.text = free ? '0' : '';
                }),
              ),
              if (_offlinePriceCtrl.text.trim() != '0') ...[
                const SizedBox(height: 8),
                _Field(
                  label: 'Цена очного приёма (сом)',
                  controller: _offlinePriceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ],
            const SizedBox(height: 8),
            _CheckRow(
              label: 'Онлайн-консультация',
              value: _hasOnline,
              onChanged: (v) => setState(() => _hasOnline = v),
            ),
            if (_hasOnline) ...[
              const SizedBox(height: 8),
              _FreeCheckRow(
                isFree: _onlinePriceCtrl.text.trim() == '0',
                onChanged: (free) => setState(() {
                  _onlinePriceCtrl.text = free ? '0' : '';
                }),
              ),
              if (_onlinePriceCtrl.text.trim() != '0') ...[
                const SizedBox(height: 8),
                _Field(
                  label: 'Цена онлайн (сом)',
                  controller: _onlinePriceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ],
          ],
        ),

        _Section(
          title: 'Образование и опыт',
          icon: PhosphorIconsRegular.graduationCap,
          children: [
            _Field(label: 'Образование', controller: _educationCtrl, maxLines: 3),
            const SizedBox(height: 12),
            _Field(
              label: 'Стаж (лет)',
              controller: _expCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            _Field(label: 'О себе', controller: _bioCtrl, maxLines: 4),
            const SizedBox(height: 12),
            _Field(label: 'Язык консультации', controller: _langCtrl),
          ],
        ),

        _Section(
          title: 'Услуги',
          icon: PhosphorIconsRegular.listBullets,
          children: [
            ..._services.asMap().entries.map((e) => _ServiceRow(
                  entry: e.value,
                  onChanged: (updated) {
                    setState(() => _services[e.key] = updated);
                  },
                  onRemove: () => setState(() => _services.removeAt(e.key)),
                )),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(
                  () => _services.add(const ServiceEntry())),
              icon: const Icon(PhosphorIconsRegular.plus, size: 18),
              label: const Text('Добавить услугу'),
            ),
          ],
        ),

        _Section(
          title: 'Контакты',
          icon: PhosphorIconsRegular.phone,
          children: [
            _Field(
              label: 'WhatsApp (номер с +)',
              controller: _waCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 13,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d]'))],
            ),
            const SizedBox(height: 12),
            _Field(label: 'Telegram (@username)', controller: _tgCtrl),
            const SizedBox(height: 12),
            _Field(label: 'Instagram (@username)', controller: _igCtrl),
          ],
        ),

        _Section(
          title: 'График приёма',
          icon: PhosphorIconsRegular.calendarCheck,
          children: _schedules
              .map((s) => _ScheduleRow(
                    entry: s,
                    onChanged: (updated) {
                      setState(() => _schedules[s.dayOfWeek] = updated);
                    },
                  ))
              .toList(),
        ),

        // ── Смена клиники ────────────────────────────────────────────────
        _Section(
          title: 'Клиника',
          icon: PhosphorIconsRegular.hospital,
          children: [
            if (_currentClinicName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.checkCircle,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentClinicName!,
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Чтобы сменить клинику, найдите новую ниже. Ваш статус изменится на «На проверке».',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                'Вы не привязаны к клинике. Найдите клинику ниже.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
            ],

            // Выбранная новая клиника
            if (_selectedNewClinicId != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.hospital,
                        color: AppColors.primaryBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedNewClinicName ?? '',
                        style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.primaryBlue),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedNewClinicId = null;
                        _selectedNewClinicName = null;
                      }),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _isApplyingClinic ? null : _applyNewClinic,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.btnGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isApplyingClinic
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Подать заявку в эту клинику',
                            style: AppTextStyles.labelBold
                                .copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Поиск клиники
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _clinicSearchCtrl,
                onChanged: _searchClinics,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Поиск клиники по названию...',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primaryBlue, size: 20),
                  suffixIcon: _isClinicSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),
            ),

            if (_clinicResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._clinicResults.map((clinic) {
                final id = clinic['id'] as int;
                final name =
                    (clinic['name_ru'] ?? clinic['name'] ?? '') as String;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedNewClinicId = id;
                      _selectedNewClinicName = name;
                      _clinicResults = [];
                      _clinicSearchCtrl.clear();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.hospital,
                            color: AppColors.primaryBlue, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                              Text(name, style: AppTextStyles.bodyLarge),
                        ),
                        const Icon(PhosphorIconsRegular.caretRight,
                            size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'После отправки клиника получит уведомление и должна будет подтвердить изменения. Ваш текущий профиль останется видимым пациентам.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          text: _selectedNewClinicId != null
              ? 'Подать заявку в «$_selectedNewClinicName»'
              : 'Отправить на проверку в клинику',
          isLoading: _isLoading || _isApplyingClinic,
          onPressed: _isLoading || _isApplyingClinic
              ? null
              : (_selectedNewClinicId != null ? _applyNewClinic : _submit),
        ),
      ],
    );
  }

  Future<void> _cancelUpdate() async {
    setState(() => _isLoading = true);
    try {
      await _repo.cancelPendingUpdate();
      if (mounted) {
        ref.invalidate(myDoctorProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запрос отменён')),
        );
        setState(() {});
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── Pending banner ────────────────────────────────────────────────────────

class _PendingBanner extends StatelessWidget {
  final VoidCallback onCancel;

  const _PendingBanner({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning, width: 1),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.clock, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Есть запрос на проверке у клиники. Новая отправка заменит его.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Отменить',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemovedBanner extends StatelessWidget {
  const _RemovedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.warning, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Вас не видят пациенты — вы не привязаны к клинике. Выберите новую клинику.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/provider/setup'),
              child: Text(
                'Выбрать клинику',
                style: AppTextStyles.labelBold.copyWith(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section wrapper ───────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(icon, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ─── URL helper ────────────────────────────────────────────────────────────

String _resolveUrl(String url) => AppConstants.fixUrl(url);

// ─── Photo picker ──────────────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  final String? photoUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const _PhotoPicker({this.photoUrl, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                backgroundImage: photoUrl != null
                    ? NetworkImage(_resolveUrl(photoUrl!))
                    : null,
                child: photoUrl == null
                    ? const Icon(PhosphorIconsRegular.user, size: 32, color: AppColors.primaryBlue)
                    : null,
              ),
              if (isLoading)
                const Positioned.fill(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.black26,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Text(
            'Изменить фото',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 4),
          const Icon(PhosphorIconsRegular.pencil, size: 16, color: AppColors.primaryBlue),
        ],
      ),
    );
  }
}

// ─── Cover photo picker ────────────────────────────────────────────────────

class _CoverPhotoPicker extends StatelessWidget {
  final String? coverPhotoUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const _CoverPhotoPicker({this.coverPhotoUrl, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: coverPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_resolveUrl(coverPhotoUrl!)),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: coverPhotoUrl == null ? AppColors.heroGradient : null,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.image,
                            size: 18,
                            color: coverPhotoUrl != null ? Colors.white : AppColors.primaryBlue),
                        const SizedBox(width: 6),
                        Text(
                          coverPhotoUrl != null ? 'Изменить фон обложки' : 'Добавить фон обложки',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: coverPhotoUrl != null ? Colors.white : AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(PhosphorIconsRegular.pencil,
                            size: 14,
                            color: coverPhotoUrl != null ? Colors.white : AppColors.primaryBlue),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Text field ────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: const Color(0xFFF0F4FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        counterText: '',
      ),
    );
  }
}

// ─── Dropdown ──────────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: AppTextStyles.bodyLarge,
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Checkbox row ──────────────────────────────────────────────────────────

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              activeColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (v) => onChanged(v ?? false),
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}

class _FreeCheckRow extends StatelessWidget {
  final bool isFree;
  final ValueChanged<bool> onChanged;

  const _FreeCheckRow({required this.isFree, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _CheckRow(
      label: 'Бесплатно',
      value: isFree,
      onChanged: onChanged,
    );
  }
}

// ─── Service row ───────────────────────────────────────────────────────────

class _ServiceRow extends StatelessWidget {
  final ServiceEntry entry;
  final ValueChanged<ServiceEntry> onChanged;
  final VoidCallback onRemove;

  const _ServiceRow({required this.entry, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextField(
              controller: TextEditingController(text: entry.name)
                ..selection = TextSelection.collapsed(offset: entry.name.length),
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Название услуги',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: const Color(0xFFF0F4FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => onChanged(entry.copyWith(name: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: TextEditingController(text: entry.price)
                ..selection = TextSelection.collapsed(offset: entry.price.length),
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Цена',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: const Color(0xFFF0F4FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => onChanged(entry.copyWith(price: v)),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.error),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule row ──────────────────────────────────────────────────────────

class _ScheduleRow extends StatelessWidget {
  final ScheduleEntry entry;
  final ValueChanged<ScheduleEntry> onChanged;

  const _ScheduleRow({required this.entry, required this.onChanged});

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(BuildContext context, TimeOfDay initial, ValueChanged<TimeOfDay> onPick) async {
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) onPick(t);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: entry.isAvailable,
              activeColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (v) => onChanged(entry.copyWith(isAvailable: v ?? false)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(entry.label, style: AppTextStyles.labelBold),
          ),
          if (entry.isAvailable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _pickTime(context, entry.startTime,
                  (t) => onChanged(entry.copyWith(startTime: t))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_fmt(entry.startTime), style: AppTextStyles.bodySmall),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('—', style: AppTextStyles.bodySmall),
            ),
            GestureDetector(
              onTap: () => _pickTime(context, entry.endTime,
                  (t) => onChanged(entry.copyWith(endTime: t))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_fmt(entry.endTime), style: AppTextStyles.bodySmall),
              ),
            ),
          ] else
            Text(
              'Выходной',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
