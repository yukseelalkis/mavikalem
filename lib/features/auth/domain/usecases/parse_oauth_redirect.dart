import 'package:mavikalem_app/features/auth/domain/entities/oauth_redirect_payload.dart';
import 'package:mavikalem_app/features/auth/domain/repositories/auth_repository.dart';

final class ParseOAuthRedirect {
  const ParseOAuthRedirect(this._repository);

  final AuthRepository _repository;

  OAuthRedirectPayload call(Uri redirectUri, {required String expectedState}) {
    return _repository.parseRedirectUri(
      redirectUri,
      expectedState: expectedState,
    );
  }
}
