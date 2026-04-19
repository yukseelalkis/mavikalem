import 'package:mavikalem_app/features/auth/domain/entities/token_entity.dart';
import 'package:mavikalem_app/features/auth/domain/entities/oauth_authorization_request.dart';
import 'package:mavikalem_app/features/auth/domain/entities/oauth_redirect_payload.dart';

abstract interface class AuthRepository {
  OAuthAuthorizationRequest buildAuthorizationRequest();
  OAuthRedirectPayload parseRedirectUri(
    Uri redirectUri, {
    required String expectedState,
  });
  Future<TokenEntity> exchangeCodeForToken(String code);
  Future<void> saveToken(TokenEntity token);
  Future<String?> getAccessToken();
  Future<void> logout();
}
