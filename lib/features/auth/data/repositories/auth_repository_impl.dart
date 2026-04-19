import 'package:mavikalem_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mavikalem_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mavikalem_app/features/auth/domain/entities/oauth_authorization_request.dart';
import 'package:mavikalem_app/features/auth/domain/entities/oauth_redirect_payload.dart';
import 'package:mavikalem_app/features/auth/domain/entities/token_entity.dart';
import 'package:mavikalem_app/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._local);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  OAuthAuthorizationRequest buildAuthorizationRequest() {
    return _remote.buildAuthorizationRequest();
  }

  @override
  OAuthRedirectPayload parseRedirectUri(
    Uri redirectUri, {
    required String expectedState,
  }) {
    return _remote.extractCodeFromRedirect(
      redirectUri,
      expectedState: expectedState,
    );
  }

  @override
  Future<TokenEntity> exchangeCodeForToken(String code) {
    return _remote.exchangeCodeForToken(code);
  }

  @override
  Future<void> saveToken(TokenEntity token) {
    return _local.saveToken(token);
  }

  @override
  Future<String?> getAccessToken() {
    return _local.readAccessToken();
  }

  @override
  Future<void> logout() {
    return _local.clear();
  }
}
