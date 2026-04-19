import 'package:mavikalem_app/features/auth/domain/entities/token_entity.dart';
import 'package:mavikalem_app/features/auth/domain/repositories/auth_repository.dart';

final class ExchangeCodeForToken {
  const ExchangeCodeForToken(this._repository);

  final AuthRepository _repository;

  Future<TokenEntity> call(String code) =>
      _repository.exchangeCodeForToken(code);
}
