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
      final msg = e.toString().contains('already reviewed')
          ? 'Вы уже оставили отзыв этому врачу'
          : 'Ошибка отправки. Попробуйте снова.';
      state = state.copyWith(isSubmitting: false, submitError: msg);
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
