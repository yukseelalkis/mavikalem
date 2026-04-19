import 'package:mavikalem_app/features/auth/domain/entities/token_entity.dart';

final class TokenResponseModel extends TokenEntity {
  const TokenResponseModel({
    required super.accessToken,
    super.refreshToken,
    super.tokenType,
    super.expiresIn,
  });

  factory TokenResponseModel.fromJson(Map<String, dynamic> json) {
    return TokenResponseModel(
      accessToken: (json['access_token'] ?? '') as String,
      refreshToken: json['refresh_token'] as String?,
      tokenType: json['token_type'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
    );
  }
}
