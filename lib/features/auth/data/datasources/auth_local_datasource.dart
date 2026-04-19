import 'package:mavikalem_app/core/storage/secure_storage_service.dart';
import 'package:mavikalem_app/features/auth/domain/entities/token_entity.dart';

final class AuthLocalDataSource {
  const AuthLocalDataSource(this._secureStorageService);

  final SecureStorageService _secureStorageService;

  Future<void> saveToken(TokenEntity token) async {
    await _secureStorageService.saveAccessToken(token.accessToken);
    await _secureStorageService.saveRefreshToken(token.refreshToken);
  }

  Future<String?> readAccessToken() => _secureStorageService.readAccessToken();

  Future<void> clear() => _secureStorageService.clearSession();
}
