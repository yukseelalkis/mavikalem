class TokenEntity {
  const TokenEntity({
    required this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiresIn,
  });

  final String accessToken;
  final String? refreshToken;
  final String? tokenType;
  final int? expiresIn;
}
