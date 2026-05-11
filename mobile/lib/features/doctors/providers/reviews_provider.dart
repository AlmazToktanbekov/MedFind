import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reviews_repository.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class ReviewsState {
  final bool isLoading;
  final bool isSubmitting;
  final List<ReviewModel> reviews;
  final String? error;
  final String? submitError;
  final bool justSubmitted;

  const ReviewsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.reviews = const [],
    this.error,
    this.submitError,
    this.justSubmitted = false,
  });

  ReviewsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<ReviewModel>? reviews,
    Object? error = _sentinel,
    Object? submitError = _sentinel,
    bool? justSubmitted,
  }) =>
      ReviewsState(
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        reviews: reviews ?? this.reviews,
        error: error == _sentinel ? this.error : error as String?,
        submitError:
            submitError == _sentinel ? this.submitError : submitError as String?,
        justSubmitted: justSubmitted ?? this.justSubmitted,
      );
}

const _sentinel = Object();

bool _isAlreadyReviewed(Exception e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      return data['detail']?.toString().contains('already') ?? false;
    }
    return e.response?.data?.toString().contains('already') ?? false;
  }
  return e.toString().contains('already');
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class ReviewsNotifier extends StateNotifier<ReviewsState> {
  final ReviewsRepository _repo;
  final int _doctorId;

  ReviewsNotifier(this._repo, this._doctorId) : super(const ReviewsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reviews = await _repo.getReviews(_doctorId);
      state = state.copyWith(isLoading: false, reviews: reviews);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить отзывы',
      );
    }
  }

  Future<bool> submit(double rating, String? text) async {
    state = state.copyWith(isSubmitting: true, submitError: null, justSubmitted: false);
    try {
      final review = await _repo.createReview(_doctorId, rating, text);
      state = state.copyWith(
        isSubmitting: false,
        reviews: [review, ...state.reviews],
        justSubmitted: true,
      );
      return true;
    } on Exception catch (e) {
      final msg = _isAlreadyReviewed(e)
          ? 'Вы уже оставили отзыв этому врачу'
          : 'Ошибка отправки. Попробуйте снова.';
      state = state.copyWith(isSubmitting: false, submitError: msg);
      return false;
    }
  }

  Future<bool> update(int reviewId, double rating, String? text) async {
    try {
      final updated = await _repo.updateReview(reviewId, rating, text);
      state = state.copyWith(
        reviews: state.reviews
            .map((r) => r.id == reviewId ? updated : r)
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int reviewId) async {
    try {
      await _repo.deleteReview(reviewId);
      state = state.copyWith(
        reviews: state.reviews.where((r) => r.id != reviewId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearSubmitError() => state = state.copyWith(submitError: null);
}

// ─── Provider ──────────────────────────────────────────────────────────────

final reviewsProvider = StateNotifierProvider.autoDispose
    .family<ReviewsNotifier, ReviewsState, int>(
  (ref, doctorId) => ReviewsNotifier(ReviewsRepository(), doctorId),
);

// ─── Clinic reviews notifier ───────────────────────────────────────────────

class ClinicReviewsNotifier extends StateNotifier<ReviewsState> {
  final ReviewsRepository _repo;
  final int _clinicId;

  ClinicReviewsNotifier(this._repo, this._clinicId)
      : super(const ReviewsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reviews = await _repo.getClinicReviews(_clinicId);
      state = state.copyWith(isLoading: false, reviews: reviews);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить отзывы',
      );
    }
  }

  Future<bool> submit(double rating, String? text) async {
    state = state.copyWith(
        isSubmitting: true, submitError: null, justSubmitted: false);
    try {
      final review = await _repo.createClinicReview(_clinicId, rating, text);
      state = state.copyWith(
        isSubmitting: false,
        reviews: [review, ...state.reviews],
        justSubmitted: true,
      );
      return true;
    } on Exception catch (e) {
      final msg = _isAlreadyReviewed(e)
          ? 'Вы уже оставили отзыв этой клинике'
          : 'Ошибка отправки. Попробуйте снова.';
      state = state.copyWith(isSubmitting: false, submitError: msg);
      return false;
    }
  }

  Future<bool> update(int reviewId, double rating, String? text) async {
    try {
      final updated = await _repo.updateReview(reviewId, rating, text);
      state = state.copyWith(
        reviews: state.reviews
            .map((r) => r.id == reviewId ? updated : r)
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int reviewId) async {
    try {
      await _repo.deleteReview(reviewId);
      state = state.copyWith(
        reviews: state.reviews.where((r) => r.id != reviewId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearSubmitError() => state = state.copyWith(submitError: null);
}

final clinicReviewsProvider = StateNotifierProvider.autoDispose
    .family<ClinicReviewsNotifier, ReviewsState, int>(
  (ref, clinicId) => ClinicReviewsNotifier(ReviewsRepository(), clinicId),
);

// ─── Branch reviews notifier ───────────────────────────────────────────────

class BranchReviewsNotifier extends StateNotifier<ReviewsState> {
  final ReviewsRepository _repo;
  final int _branchId;

  BranchReviewsNotifier(this._repo, this._branchId)
      : super(const ReviewsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reviews = await _repo.getBranchReviews(_branchId);
      state = state.copyWith(isLoading: false, reviews: reviews);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить отзывы',
      );
    }
  }

  Future<bool> submit(double rating, String? text) async {
    state = state.copyWith(
        isSubmitting: true, submitError: null, justSubmitted: false);
    try {
      final review = await _repo.createBranchReview(_branchId, rating, text);
      state = state.copyWith(
        isSubmitting: false,
        reviews: [review, ...state.reviews],
        justSubmitted: true,
      );
      return true;
    } on Exception catch (e) {
      final msg = _isAlreadyReviewed(e)
          ? 'Вы уже оставили отзыв этой аптеке'
          : 'Ошибка отправки. Попробуйте снова.';
      state = state.copyWith(isSubmitting: false, submitError: msg);
      return false;
    }
  }

  Future<bool> update(int reviewId, double rating, String? text) async {
    try {
      final updated = await _repo.updateReview(reviewId, rating, text);
      state = state.copyWith(
        reviews: state.reviews
            .map((r) => r.id == reviewId ? updated : r)
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int reviewId) async {
    try {
      await _repo.deleteReview(reviewId);
      state = state.copyWith(
        reviews: state.reviews.where((r) => r.id != reviewId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearSubmitError() => state = state.copyWith(submitError: null);
}

final branchReviewsProvider = StateNotifierProvider.autoDispose
    .family<BranchReviewsNotifier, ReviewsState, int>(
  (ref, branchId) => BranchReviewsNotifier(ReviewsRepository(), branchId),
);
