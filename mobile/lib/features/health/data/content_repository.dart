import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class ArticleModel {
  final int id;
  final String title;
  final String? body;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;

  const ArticleModel({
    required this.id,
    required this.title,
    this.body,
    this.category,
    this.imageUrl,
    required this.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
        id: json['id'] as int,
        title: json['title_ru'] as String? ?? '',
        body: json['body_ru'] as String?,
        category: json['category'] as String?,
        imageUrl: json['image_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class HealthContent {
  final List<ArticleModel> articles;
  final List<ArticleModel> firstAid;
  final List<ArticleModel> tips;

  const HealthContent({
    required this.articles,
    required this.firstAid,
    required this.tips,
  });
}

class ContentRepository {
  final Dio _dio;

  ContentRepository() : _dio = ApiClient().dio;

  Future<List<ArticleModel>> _fetch(String path) async {
    final response = await _dio.get(path);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HealthContent> getAll() async {
    final results = await Future.wait([
      _fetch('/content/articles'),
      _fetch('/content/first-aid'),
      _fetch('/content/health-tips'),
    ]);
    return HealthContent(
      articles: results[0],
      firstAid: results[1],
      tips: results[2],
    );
  }
}
