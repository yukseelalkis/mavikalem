import 'package:mavikalem_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mavikalem_app/features/auth/domain/entities/oauth_authorization_request.dart';

final class StartOAuthLogin {
  const StartOAuthLogin(this._repository);

  final AuthRepository _repository;

  OAuthAuthorizationRequest call() => _repository.buildAuthorizationRequest();
}
