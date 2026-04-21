import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Siparis satiri id -> okutulan adet (cihazda kalici).
final class PackProgressStorage {
  const PackProgressStorage();

  static String keyForOrder(int orderId) => 'pack_progress_order_$orderId';

  Future<Map<int, double>> load(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyForOrder(orderId));
    if (raw == null || raw.isEmpty) return <int, double>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <int, double>{};
      final out = <int, double>{};
      for (final e in decoded.entries) {
        final id = int.tryParse(e.key);
        final v = e.value;
        if (id == null) continue;
        if (v is num) {
          out[id] = v.toDouble();
        }
      }
      return out;
    } catch (_) {
      return <int, double>{};
    }
  }

  Future<void> save(int orderId, Map<int, double> counts) async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{
      for (final e in counts.entries) e.key.toString(): e.value,
    };
    await prefs.setString(keyForOrder(orderId), jsonEncode(map));
  }

  Future<void> clear(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyForOrder(orderId));
  }
}
