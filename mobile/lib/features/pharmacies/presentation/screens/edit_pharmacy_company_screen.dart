import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/pharmacies_repository.dart';
import 'pharmacy_manage_screen.dart';

final _editCompanyRepoProvider =
    Provider<PharmaciesRepository>((_) => PharmaciesRepository());

class EditPharmacyCompanyScreen extends ConsumerStatefulWidget {
  const EditPharmacyCompanyScreen({super.key});

  @override
  ConsumerState<EditPharmacyCompanyScreen> createState() =>
      _EditPharmacyCompanyScreenState();
}

class _EditPharmacyCompanyScreenState
    extends ConsumerState<EditPharmacyCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  PharmacyCompanyModel? _company;

  String? _newLogoPath;
  String? _newCoverPath;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCompany() async {
    setState(() => _isLoading = true);
    try {
      final company =
          await ref.read(_editCompanyRepoProvider).getMyCompany();
      if (company == null) {
        setState(() {
          _error = 'Компания не найдена';
          _isLoading = false;
        });
        return;
      }
      _company = company;
      _nameCtrl.text = company.name;
      final phone = company.mainPhone ?? '';
      _phoneCtrl.text =
          phone.startsWith('+996') ? phone.substring(4) : phone;
      _websiteCtrl.text = company.website ?? '';
      _descCtrl.text = company.description ?? '';
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildCoverPicker() {
    final existingCover = _company?.coverPhotoUrl;
    return GestureDetector(
      onTap: _pickCover,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.backgroundChip,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_newCoverPath != null)
              Image.file(File(_newCoverPath!), fit: BoxFit.cover)
            else if (existingCover != null)
              CachedNetworkImage(imageUrl: existingCover, fit: BoxFit.cover)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsRegular.image,
                      color: AppColors.warning, size: 32),
                  const SizedBox(height: 8),
                  Text('Фото обложки',
                      style: AppTextStyles.labelBold
                          .copyWith(color: AppColors.warning)),
                  const SizedBox(height: 4),
                  Text('Баннер за логотипом на профиле',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            if (_newCoverPath != null || existingCover != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(PhosphorIconsRegular.pencilSimple,
                      color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (file == null) return;
    setState(() => _newLogoPath = file.path);
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (file == null) return;
    setState(() => _newCoverPath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_company == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repo = ref.read(_editCompanyRepoProvider);

      String? logoUrl = _company!.logoUrl;
      if (_newLogoPath != null) {
        logoUrl = await repo.uploadPhoto(_newLogoPath!);
      }

      String? coverPhotoUrl = _company!.coverPhotoUrl;
      if (_newCoverPath != null) {
        coverPhotoUrl = await repo.uploadPhoto(_newCoverPath!);
      }

      final phone = _phoneCtrl.text.trim();
      final mainPhone = phone.isNotEmpty ? '+996$phone' : null;

      await repo.updateCompany(
        companyId: _company!.id,
        name: _nameCtrl.text.trim(),
        logoUrl: logoUrl,
        coverPhotoUrl: coverPhotoUrl,
        mainPhone: mainPhone,
        website: _websiteCtrl.text.trim().isNotEmpty
            ? _websiteCtrl.text.trim()
            : null,
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
      );

      ref.invalidate(myPharmacyCompanyProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _error = 'Ошибка сохранения: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Обложка профиля
                    _buildCoverPicker(),
                    const SizedBox(height: 16),

                    // Логотип
                    Center(
                      child: GestureDetector(
                        onTap: _pickLogo,
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.backgroundChip,
                                border: Border.all(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _newLogoPath != null
                                    ? Image.file(File(_newLogoPath!),
                                        fit: BoxFit.cover)
                                    : (_company?.logoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: _company!.logoUrl!,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, _, _) =>
                                                const Icon(
                                                    PhosphorIconsRegular.pill,
                                                    color: AppColors.warning,
                                                    size: 36),
                                          )
                                        : const Icon(PhosphorIconsRegular.pill,
                                            color: AppColors.warning,
                                            size: 36)),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(PhosphorIconsRegular.camera,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text('Логотип',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(height: 28),

                    _label('Название *'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _nameCtrl,
                      hint: 'Название аптечной сети',
                      icon: PhosphorIconsRegular.pill,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Главный телефон'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        maxLength: 9,
                        style: AppTextStyles.bodyLarge,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (v.trim().length < 9) {
                            return 'Введите 9 цифр номера';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: '700 000 000',
                          hintStyle: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          prefixText: '+996 ',
                          prefixStyle: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                          prefixIcon: Padding(
                            padding:
                                const EdgeInsets.only(left: 16, right: 8),
                            child: Icon(PhosphorIconsRegular.phone,
                                color: AppColors.warning, size: 20),
                          ),
                          prefixIconConstraints: const BoxConstraints(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          counterText: '',
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.error, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.error, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label('Сайт'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _websiteCtrl,
                      hint: 'https://apteka.kg',
                      icon: PhosphorIconsRegular.globe,
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!v.trim().startsWith('https://')) {
                          return 'Ссылка должна начинаться с https://';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Описание'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _descCtrl,
                      hint: 'Кратко о вашей аптечной сети...',
                      icon: PhosphorIconsRegular.textAlignLeft,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    GradientButton(
                      text: 'Сохранить',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

Widget _label(String text) => Text(
      text,
      style: AppTextStyles.labelBold.copyWith(color: AppColors.textPrimary),
    );

Widget _field({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
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
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        prefixIcon: maxLines == 1
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(icon, color: AppColors.warning, size: 20),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: InputBorder.none,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    ),
  );
}
