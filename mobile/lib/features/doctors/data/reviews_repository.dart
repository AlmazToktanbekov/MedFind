import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class ReviewModel {
  final int id;
  final int authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final double rating;
  final String? text;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    required this.rating,
    this.text,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as int,
        authorId: json['author_id'] as int,
        authorName: json['author_name'] as String?,
        authorAvatarUrl: json['author_avatar_url'] as String?,
        rating: (json['rating'] as num).toDouble(),
        text: json['text'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ReviewsRepository {
  final Dio _dio;

  ReviewsRepository() : _dio = ApiClient().dio;

  // ─── Doctor ────────────────────────────────────────────────────────────

  Future<List<ReviewModel>> getReviews(int doctorId) async {
    final response = await _dio.get('/reviews/doctor/$doctorId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewModel> createReview(
      int doctorId, double rating, String? text) async {
    final response = await _dio.post(
      '/reviews/doctor/$doctorId',
      data: {
        'rating': rating,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
      },
    );
    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Clinic ────────────────────────────────────────────────────────────

  Future<List<ReviewModel>> getClinicReviews(int clinicId) async {
    final response = await _dio.get('/reviews/clinic/$clinicId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewModel> createClinicReview(
      int clinicId, double rating, String? text) async {
    final response = await _dio.post(
      '/reviews/clinic/$clinicId',
      data: {
        'rating': rating,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
      },
    );
    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Update / Delete (общие для всех типов) ───────────────────────────

  Future<ReviewModel> updateReview(
      int reviewId, double rating, String? text) async {
    final response = await _dio.patch(
      '/reviews/$reviewId',
      data: {
        'rating': rating,
        'text': text?.trim().isEmpty == true ? null : text?.trim(),
      },
    );
    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteReview(int reviewId) async {
    await _dio.delete('/reviews/$reviewId');
  }

  // ─── Pharmacy branch ───────────────────────────────────────────────────

  Future<List<ReviewModel>> getBranchReviews(int branchId) async {
    final response = await _dio.get('/reviews/pharmacy-branch/$branchId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewModel> createBranchReview(
      int branchId, double rating, String? text) async {
    final response = await _dio.post(
      '/reviews/pharmacy-branch/$branchId',
      data: {
        'rating': rating,
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
      },
    );
    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }
}
