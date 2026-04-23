import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/features/orders/data/pack_progress_storage.dart';

final packProgressStorageProvider = Provider<PackProgressStorage>(
  (ref) => const PackProgressStorage(),
);

/// Siparis bazli okutulan adetler (satir id -> miktar).
final packProgressProvider =
    StateNotifierProvider.family<PackProgressNotifier, Map<int, double>, int>(
  (ref, orderId) {
    final storage = ref.watch(packProgressStorageProvider);
    return PackProgressNotifier(storage, orderId);
  },
);

final class PackProgressNotifier extends StateNotifier<Map<int, double>> {
  PackProgressNotifier(this._storage, this.orderId) : super({}) {
    _load();
  }

  final PackProgressStorage _storage;
  final int orderId;

  Future<void> _load() async {
    final loaded = await _storage.load(orderId);
    state = loaded;
  }

  Future<void> incrementLine(int lineId, double delta) async {
    if (delta == 0) return;
    final next = Map<int, double>.from(state);
    next[lineId] = (next[lineId] ?? 0) + delta;
    if (next[lineId]! <= 0) {
      next.remove(lineId);
    }
    state = next;
    await _storage.save(orderId, next);
  }

  Future<void> setLineCount(int lineId, double value) async {
    final next = Map<int, double>.from(state);
    if (value <= 0) {
      next.remove(lineId);
    } else {
      next[lineId] = value;
    }
    state = next;
    await _storage.save(orderId, next);
  }

  Future<void> clearAll() async {
    state = {};
    await _storage.clear(orderId);
  }
}
