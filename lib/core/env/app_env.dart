import 'package:flutter_dotenv/flutter_dotenv.dart';

final class AppEnv {
  const AppEnv._();

  static const String _supabaseUrlKey = 'SUPABASE_URL';
  static const String _supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _required(_supabaseUrlKey);
  static String get supabaseAnonKey => _required(_supabaseAnonKeyKey);

  static String _required(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required env key: $key. '
        'Set it in .env file before running the app.',
      );
    }
    return value;
  }
}
