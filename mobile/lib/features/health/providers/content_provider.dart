import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content_repository.dart';

final contentRepositoryProvider =
    Provider<ContentRepository>((_) => ContentRepository());

final healthContentProvider =
    FutureProvider.autoDispose<HealthContent>((ref) async {
  final repo = ref.read(contentRepositoryProvider);
  return repo.getAll();
});
