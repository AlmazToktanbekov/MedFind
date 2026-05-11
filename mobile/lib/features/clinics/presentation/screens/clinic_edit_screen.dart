import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/clinic_model.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../clinics/data/clinics_repository.dart';
import '../../providers/clinics_provider.dart';

// ─── Provider ──────────────────────────────────────────────────────────────

final _clinicsRepoEditProvider =
    Provider<ClinicsRepository>((_) => ClinicsRepository());

// ─── Screen ────────────────────────────────────────────────────────────────

class ClinicEditScreen extends ConsumerStatefulWidget {
  final int clinicId;
  const ClinicEditScreen({super.key, required this.clinicId});

  @override
  ConsumerState<ClinicEditScreen> createState() => _ClinicEditScreenState();
}

class _ClinicEditScreenState extends ConsumerState<ClinicEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _telegramCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  List<String> _selectedCategories = [];

  // Фото — существующие URL + новые локальные пути
  List<String> _existingPhotoUrls = [];
  List<int> _existingPhotoIds = [];
  final List<String> _newPhotoPaths = [];

  // Лого
  String? _existingLogoUrl;
  String? _newLogoPath;

  static const _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  late List<bool> _dayEnabled;
  late List<TimeOfDay> _startTimes;
  late List<TimeOfDay> _endTimes;

  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _mapUrlCtrl.dispose();
    _websiteCtrl.dispose();
    _whatsappCtrl.dispose();
    _telegramCtrl.dispose();
    _instagramCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _initFromClinic(ClinicModel clinic) {
    if (_initialized) return;
    _initialized = true;

    _nameCtrl.text = clinic.name;
    _phoneCtrl.text = clinic.phone?.replaceFirst('+', '') ?? '';
    _descCtrl.text = clinic.description ?? '';
    _addressCtrl.text = clinic.address ?? '';
    _mapUrlCtrl.text = clinic.mapUrl ?? '';
    _websiteCtrl.text = clinic.website ?? '';
    _whatsappCtrl.text = clinic.whatsapp ?? '';
    _telegramCtrl.text =
        (clinic.telegram ?? '').replaceFirst('@', '');
    _instagramCtrl.text =
        (clinic.instagram ?? '').replaceFirst('@', '');
    _emailCtrl.text = clinic.email ?? '';
    _existingLogoUrl = clinic.logoUrl;

    if (clinic.category != null && clinic.category!.isNotEmpty) {
      _selectedCategories = clinic.category!
          .split(', ')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    _existingPhotoUrls = clinic.photos.map((p) => p.url).toList();
    _existingPhotoIds = clinic.photos.map((p) => p.id).toList();

    _parseSchedule(clinic.workingHours ?? '');
  }

  void _parseSchedule(String raw) {
    _dayEnabled = List.filled(7, false);
    _startTimes =
        List.filled(7, const TimeOfDay(hour: 9, minute: 0));
    _endTimes =
        List.filled(7, const TimeOfDay(hour: 18, minute: 0));

    if (raw.isEmpty) {
      for (int i = 0; i < 5; i++) {
        _dayEnabled[i] = true;
      }
      return;
    }

    final entries = raw.split(RegExp(r',\s*(?=[А-Я][а-я]? )'));
    for (final entry in entries) {
      final parts = entry.trim().split(' ');
      if (parts.isEmpty) continue;
      final dayIdx = _dayLabels.indexOf(parts[0]);
      if (dayIdx < 0) continue;
      _dayEnabled[dayIdx] = true;
      if (parts.length >= 2) {
        final times = parts[1].split('–');
        if (times.length == 2) {
          _startTimes[dayIdx] = _parseTime(times[0]);
          _endTimes[dayIdx] = _parseTime(times[1]);
        }
      }
    }
  }

  TimeOfDay _parseTime(String s) {
    final p = s.split(':');
    if (p.length == 2) {
      final h = int.tryParse(p[0]) ?? 9;
      final m = int.tryParse(p[1]) ?? 0;
      return TimeOfDay(hour: h, minute: m);
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _buildHoursString() {
    final parts = <String>[];
    for (int i = 0; i < 7; i++) {
      if (!_dayEnabled[i]) continue;
      final st = _startTimes[i];
      final en = _endTimes[i];
      final sf =
          '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}';
      final ef =
          '${en.hour.toString().padLeft(2, '0')}:${en.minute.toString().padLeft(2, '0')}';
      parts.add('${_dayLabels[i]} $sf–$ef');
    }
    return parts.join(', ');
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _newLogoPath = file.path);
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _newPhotoPaths.add(file.path));
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoUrls.removeAt(index);
      _existingPhotoIds.removeAt(index);
    });
  }

  void _removeNewPhoto(int index) {
    setState(() => _newPhotoPaths.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Выберите хотя бы одно направление')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(_clinicsRepoEditProvider);

      // Загрузка нового логотипа
      String? logoUrl = _existingLogoUrl;
      if (_newLogoPath != null) {
        logoUrl = await repo.uploadPhoto(_newLogoPath!);
      }

      // Удаление фото которые убрал пользователь — через существующие id
      final currentClinic = ref.read(clinicByIdProvider(widget.clinicId)).valueOrNull;
      if (currentClinic != null) {
        for (final photo in currentClinic.photos) {
          if (!_existingPhotoIds.contains(photo.id)) {
            try {
              await repo.deletePhoto(widget.clinicId, photo.id);
            } catch (_) {}
          }
        }
      }

      // Загрузка новых фото
      for (final path in _newPhotoPaths) {
        final url = await repo.uploadPhoto(path);
        await repo.addPhoto(widget.clinicId, url);
      }

      // Сохранение основных данных
      final phone = _phoneCtrl.text.trim();
      await repo.updateClinic(widget.clinicId, {
        'name_ru': _nameCtrl.text.trim(),
        'phone': phone.isNotEmpty ? '+$phone' : null,
        'description_ru': _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        'address_ru': _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : null,
        'map_url': _mapUrlCtrl.text.trim().isNotEmpty
            ? _mapUrlCtrl.text.trim()
            : null,
        'website': _websiteCtrl.text.trim().isNotEmpty
            ? _websiteCtrl.text.trim()
            : null,
        'category_ru': _selectedCategories.join(', '),
        'whatsapp': _whatsappCtrl.text.trim().isNotEmpty
            ? _whatsappCtrl.text.trim()
            : null,
        'telegram': _telegramCtrl.text.trim().isNotEmpty
            ? '@${_telegramCtrl.text.trim()}'
            : null,
        'instagram': _instagramCtrl.text.trim().isNotEmpty
            ? '@${_instagramCtrl.text.trim()}'
            : null,
        'email': _emailCtrl.text.trim().isNotEmpty
            ? _emailCtrl.text.trim()
            : null,
        'working_hours_ru': _buildHoursString(),
        'logo_url': logoUrl,
      });

      // Обновляем провайдер
      ref.invalidate(clinicByIdProvider(widget.clinicId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Профиль сохранён'),
            backgroundColor: AppColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicAsync = ref.watch(clinicByIdProvider(widget.clinicId));

    return clinicAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Редактировать')),
        body: Center(child: Text('Ошибка: $e')),
      ),
      data: (clinic) {
        _initFromClinic(clinic);
        return _buildForm(context);
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Редактировать профиль',
            style: AppTextStyles.headingMedium),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Логотип
              _section('Логотип'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 1.5),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: _newLogoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(File(_newLogoPath!),
                              fit: BoxFit.cover))
                      : _existingLogoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(AppConstants.fixUrl(_existingLogoUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _logoPlaceholder()))
                          : _logoPlaceholder(),
                ),
              ),
              const SizedBox(height: 24),

              // Основная информация
              _section('Основная информация'),
              const SizedBox(height: 12),
              _label('Название клиники *'),
              const SizedBox(height: 6),
              _field(_nameCtrl, 'МЦ Авиценна',
                  PhosphorIconsRegular.buildingOffice,
                  validator: (v) =>
                      v == null || v.trim().length < 2
                          ? 'Введите название'
                          : null),
              const SizedBox(height: 14),
              _label('Номер телефона'),
              const SizedBox(height: 6),
              _phoneFieldWidget(),
              const SizedBox(height: 14),
              _label('Описание'),
              const SizedBox(height: 6),
              _field(_descCtrl, 'Кратко о клинике',
                  PhosphorIconsRegular.textAlignLeft,
                  maxLines: 3),
              const SizedBox(height: 14),
              _label('Сайт'),
              const SizedBox(height: 6),
              _field(_websiteCtrl, 'https://clinic.kg',
                  PhosphorIconsRegular.globe,
                  keyboardType: TextInputType.url),
              const SizedBox(height: 14),
              _label('Направления / Категории *'),
              const SizedBox(height: 6),
              _CategoryPickerButton(
                selected: _selectedCategories,
                onChanged: (v) =>
                    setState(() => _selectedCategories = v),
              ),
              const SizedBox(height: 24),

              // Адрес
              _section('Адрес'),
              const SizedBox(height: 12),
              _label('Адрес *'),
              const SizedBox(height: 6),
              _field(_addressCtrl, 'г. Бишкек, ул. Киевская, 96',
                  PhosphorIconsRegular.mapPin,
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Введите адрес'
                          : null),
              const SizedBox(height: 14),
              _label('Ссылка на карту'),
              const SizedBox(height: 6),
              _field(_mapUrlCtrl, 'https://go.2gis.com/...',
                  PhosphorIconsRegular.mapPin,
                  keyboardType: TextInputType.url),
              const SizedBox(height: 24),

              // Контакты
              _section('Контакты'),
              const SizedBox(height: 12),
              _label('WhatsApp'),
              const SizedBox(height: 6),
              _field(_whatsappCtrl, '996700000000',
                  PhosphorIconsRegular.whatsappLogo,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _label('Telegram'),
              const SizedBox(height: 6),
              _prefixField(
                  _telegramCtrl, 'username',
                  PhosphorIconsRegular.telegramLogo),
              const SizedBox(height: 14),
              _label('Instagram'),
              const SizedBox(height: 6),
              _prefixField(
                  _instagramCtrl, 'username',
                  PhosphorIconsRegular.instagramLogo),
              const SizedBox(height: 14),
              _label('Email'),
              const SizedBox(height: 6),
              _field(_emailCtrl, 'clinic@example.kg',
                  PhosphorIconsRegular.envelope,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),

              // График работы
              _section('Режим работы'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Column(
                  children: List.generate(7, (i) {
                    return _ScheduleRow(
                      label: _dayLabels[i],
                      enabled: _dayEnabled[i],
                      start: _startTimes[i],
                      end: _endTimes[i],
                      onToggle: (v) =>
                          setState(() => _dayEnabled[i] = v),
                      onStartTap: () async {
                        final picked = await showTimePicker(
                            context: context,
                            initialTime: _startTimes[i]);
                        if (picked != null) {
                          setState(() => _startTimes[i] = picked);
                        }
                      },
                      onEndTap: () async {
                        final picked = await showTimePicker(
                            context: context,
                            initialTime: _endTimes[i]);
                        if (picked != null) {
                          setState(() => _endTimes[i] = picked);
                        }
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Фотографии
              _section('Фотографии'),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: _existingPhotoUrls.length +
                    _newPhotoPaths.length +
                    1,
                itemBuilder: (context, i) {
                  final totalExisting = _existingPhotoUrls.length;
                  final totalNew = _newPhotoPaths.length;

                  if (i < totalExisting) {
                    return _photoTile(
                      child: Image.network(AppConstants.fixUrl(_existingPhotoUrls[i]),
                          fit: BoxFit.cover),
                      onRemove: () => _removeExistingPhoto(i),
                    );
                  } else if (i < totalExisting + totalNew) {
                    final ni = i - totalExisting;
                    return _photoTile(
                      child: Image.file(File(_newPhotoPaths[ni]),
                          fit: BoxFit.cover),
                      onRemove: () => _removeNewPhoto(ni),
                    );
                  } else {
                    return GestureDetector(
                      onTap: _addPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primaryBlue
                                  .withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(PhosphorIconsRegular.plus,
                                color: AppColors.primaryBlue, size: 22),
                            const SizedBox(height: 4),
                            Text('Добавить',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),

              GradientButton(
                text: 'Сохранить',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _save,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(PhosphorIconsRegular.image,
            color: AppColors.primaryBlue, size: 26),
        const SizedBox(height: 4),
        Text('Лого',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.primaryBlue, fontSize: 11)),
      ],
    );
  }

  Widget _photoTile(
      {required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.expand(child: child)),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title) => Text(title,
      style: AppTextStyles.headingMedium.copyWith(fontSize: 18));

  Widget _label(String text) => Text(text,
      style: AppTextStyles.labelBold
          .copyWith(color: AppColors.textPrimary));

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyLarge,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
          prefixIcon: maxLines == 1
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Icon(icon,
                      color: AppColors.primaryBlue, size: 20),
                )
              : null,
          prefixIconConstraints: const BoxConstraints(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _phoneFieldWidget() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextFormField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        style: AppTextStyles.bodyLarge,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-]')),
          LengthLimitingTextInputFormatter(15),
        ],
        decoration: InputDecoration(
          hintText: '996 312 000 000',
          hintStyle: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: const Icon(PhosphorIconsRegular.phone,
                color: AppColors.primaryBlue, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          prefix: Text('+',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textPrimary)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _prefixField(
      TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextFormField(
        controller: ctrl,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          prefix: Text('@',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textPrimary)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ─── Schedule row ──────────────────────────────────────────────────────────

class _ScheduleRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;
  final ValueChanged<bool> onToggle;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const _ScheduleRow({
    required this.label,
    required this.enabled,
    required this.start,
    required this.end,
    required this.onToggle,
    required this.onStartTap,
    required this.onEndTap,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(label,
                style: AppTextStyles.labelBold
                    .copyWith(color: AppColors.textPrimary)),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: AppColors.primaryBlue,
            activeTrackColor:
                AppColors.primaryBlue.withValues(alpha: 0.4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (enabled) ...[
            const SizedBox(width: 8),
            _TimeChip(time: _fmt(start), onTap: onStartTap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('—',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            _TimeChip(time: _fmt(end), onTap: onEndTap),
          ] else ...[
            const SizedBox(width: 8),
            Text('Выходной',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _TimeChip({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(time,
            style: AppTextStyles.labelBold
                .copyWith(color: AppColors.primaryBlue)),
      ),
    );
  }
}

// ─── Category picker (same as clinic setup) ───────────────────────────────

class _CategoryPickerButton extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _CategoryPickerButton(
      {required this.selected, required this.onChanged});

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryBottomSheet(
        selected: List<String>.from(selected),
        onDone: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected.map((cat) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        final updated =
                            List<String>.from(selected)..remove(cat);
                        onChanged(updated);
                      },
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: () => _openSheet(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.list,
                    color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selected.isEmpty
                        ? 'Выбрать направления'
                        : '${selected.length} выбрано — изменить',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.primaryBlue,
                    ),
                  ),
                ),
                const Icon(PhosphorIconsRegular.caretDown,
                    color: AppColors.primaryBlue, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryBottomSheet extends StatefulWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onDone;

  const _CategoryBottomSheet(
      {required this.selected, required this.onDone});

  @override
  State<_CategoryBottomSheet> createState() =>
      _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<_CategoryBottomSheet> {
  late List<String> _local;

  @override
  void initState() {
    super.initState();
    _local = List<String>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.backgroundChip,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                    child: Text('Направления',
                        style: AppTextStyles.headingMedium)),
                if (_local.isNotEmpty)
                  Text('${_local.length} выбрано',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primaryBlue)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  AppConstants.clinicCategories.length,
              itemBuilder: (context, i) {
                final cat =
                    AppConstants.clinicCategories[i];
                final isSelected = _local.contains(cat);
                return ListTile(
                  onTap: () => setState(() => isSelected
                      ? _local.remove(cat)
                      : _local.add(cat)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  title: Text(cat,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      )),
                  trailing: isSelected
                      ? Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14),
                        )
                      : Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.backgroundChip,
                                  width: 2)),
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24,
                MediaQuery.of(context).padding.bottom + 16),
            child: GestureDetector(
              onTap: () {
                widget.onDone(_local);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.btnGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _local.isEmpty
                        ? 'Выбрать'
                        : 'Готово (${_local.length})',
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
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
