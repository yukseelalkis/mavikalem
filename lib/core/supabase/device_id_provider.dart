import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/core/di/providers.dart';
import 'package:uuid/uuid.dart';

const String _deviceIdStorageKey = 'picking_device_id';

final deviceIdProvider = FutureProvider<String>((ref) async {
  final storage = ref.watch(flutterSecureStorageProvider);
  final existing = await storage.read(key: _deviceIdStorageKey);
  if (existing != null && existing.trim().isNotEmpty) {
    return existing.trim();
  }

  final generated = const Uuid().v4();
  await storage.write(key: _deviceIdStorageKey, value: generated);
  return generated;
});
