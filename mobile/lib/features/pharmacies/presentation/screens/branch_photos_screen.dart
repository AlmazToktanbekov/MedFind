import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/pharmacy_model.dart';
import '../../data/pharmacies_repository.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class _BranchPhotosState {
  final bool isLoading;
  final bool isUploading;
  final List<PharmacyBranchPhotoModel> photos;
  final String? error;

  const _BranchPhotosState({
    this.isLoading = false,
    this.isUploading = false,
    this.photos = const [],
    this.error,
  });

  _BranchPhotosState copyWith({
    bool? isLoading,
    bool? isUploading,
    List<PharmacyBranchPhotoModel>? photos,
    String? error,
  }) =>
      _BranchPhotosState(
        isLoading: isLoading ?? this.isLoading,
        isUploading: isUploading ?? this.isUploading,
        photos: photos ?? this.photos,
        error: error,
      );
}

class _BranchPhotosNotifier extends StateNotifier<_BranchPhotosState> {
  final PharmaciesRepository _repo;
  final int _branchId;

  _BranchPhotosNotifier(this._repo, this._branchId)
      : super(const _BranchPhotosState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final branch = await _repo.getBranchById(_branchId);
      state = state.copyWith(isLoading: false, photos: branch.photos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (file == null) return;

    state = state.copyWith(isUploading: true);
    try {
      final url = await _repo.uploadPhoto(file.path);
      final updated = await _repo.addBranchPhoto(_branchId, url);
      state = state.copyWith(isUploading: false, photos: updated.photos);
    } catch (_) {
      state = state.copyWith(isUploading: false, error: 'Ошибка загрузки');
    }
  }

  Future<void> deletePhoto(int photoId) async {
    try {
      await _repo.deleteBranchPhoto(_branchId, photoId);
      state = state.copyWith(
          photos: state.photos.where((p) => p.id != photoId).toList());
    } catch (_) {}
  }
}

final _branchPhotosProvider = StateNotifierProvider.autoDispose
    .family<_BranchPhotosNotifier, _BranchPhotosState, int>(
  (ref, branchId) =>
      _BranchPhotosNotifier(PharmaciesRepository(), branchId),
);

// ─── Screen ────────────────────────────────────────────────────────────────

class BranchPhotosScreen extends ConsumerWidget {
  final int branchId;
  const BranchPhotosScreen({super.key, required this.branchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_branchPhotosProvider(branchId));
    final notifier = ref.read(_branchPhotosProvider(branchId).notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        title: Text('Фото филиала', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.isUploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(PhosphorIconsRegular.plus,
                  color: AppColors.primaryBlue),
              onPressed: notifier.addPhoto,
              tooltip: 'Добавить фото',
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.photos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIconsRegular.imageSquare,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('Нет фотографий',
                          style: AppTextStyles.headingMedium
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Нажмите + чтобы добавить',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.photos.length,
                  itemBuilder: (_, i) {
                    final photo = state.photos[i];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: photo.url,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Container(
                              color: AppColors.backgroundChip,
                              child: const Icon(
                                  PhosphorIconsRegular.image,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () =>
                                _confirmDelete(context, notifier, photo.id),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  void _confirmDelete(
      BuildContext context, _BranchPhotosNotifier notifier, int photoId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить фото?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.deletePhoto(photoId);
            },
            child: const Text('Удалить',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
