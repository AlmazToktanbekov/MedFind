import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final currentUserIdProvider = FutureProvider<int?>((ref) async {
  const storage = FlutterSecureStorage();
  final val = await storage.read(key: 'user_id');
  return val != null ? int.tryParse(val) : null;
});
