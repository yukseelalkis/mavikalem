import 'package:mavikalem_app/core/error/failures.dart';

final class ApiResponseParser {
  static List<dynamic> parseList(dynamic raw) {
    if (raw is List<dynamic>) {
      return raw;
    }

    if (raw is Map<String, dynamic>) {
      const candidates = <String>[
        'data',
        'items',
        'results',
        'orders',
        'products',
      ];
      for (final key in candidates) {
        final value = raw[key];
        if (value is List<dynamic>) {
          return value;
        }
      }
    }

    throw const ParsingFailure(
      'Liste formatindaki API cevabi parse edilemedi.',
    );
  }

  static Map<String, dynamic> parseMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    throw const ParsingFailure(
      'JSON nesnesi formatindaki API cevabi parse edilemedi.',
    );
  }
}
