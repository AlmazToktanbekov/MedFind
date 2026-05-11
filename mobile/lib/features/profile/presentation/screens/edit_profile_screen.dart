import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  bool _saving = false;
  String? _currentAvatarUrl;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameCtrl.text = profile.fullName ?? '';
    _currentAvatarUrl = profile.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<String?> _uploadPhoto(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: 'avatar.jpg'),
    });
    final res = await _dio.post('/upload/photo', data: form);
    return res.data['url'] as String?;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      String? avatarUrl = _currentAvatarUrl;

      if (_pickedImage != null) {
        avatarUrl = await _uploadPhoto(_pickedImage!);
      }

      await _dio.patch('/auth/me', data: {
        'full_name': name,
        'avatar_url': avatarUrl,
      });

      await _storage.write(key: 'full_name', value: name);
      await ref.read(profileProvider.notifier).refresh();

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Редактировать профиль', style: AppTextStyles.headingMedium),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 16),

          // ── Аватар ────────────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  _buildAvatar(),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.camera,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Center(
            child: Text(
              'Нажмите, чтобы изменить фото',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),

          const SizedBox(height: 32),

          // ── Имя ───────────────────────────────────────────────────────
          Text('Имя', style: AppTextStyles.labelBold),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: AppTextStyles.bodyLarge,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Ваше имя',
              hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              filled: true,
              fillColor: const Color(0xFFEEF2FF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ── Кнопка сохранить ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.btnGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Сохранить',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim().split(' ').take(2).map((p) => p[0]).join().toUpperCase()
        : 'П';

    if (_pickedImage != null) {
      return CircleAvatar(
        radius: 54,
        backgroundImage: FileImage(_pickedImage!),
      );
    }

    if (_currentAvatarUrl != null) {
      return CircleAvatar(
        radius: 54,
        backgroundColor: AppColors.backgroundChip,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: AppConstants.fixUrl(_currentAvatarUrl!),
            width: 108,
            height: 108,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => _InitialsCircle(initials: initials),
          ),
        ),
      );
    }

    return _InitialsCircle(initials: initials, radius: 54);
  }
}

class _InitialsCircle extends StatelessWidget {
  final String initials;
  final double radius;

  const _InitialsCircle({required this.initials, this.radius = 54});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryBlue,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.55,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
