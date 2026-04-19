class OAuthRedirectPayload {
  const OAuthRedirectPayload({required this.code, required this.returnedState});

  final String code;
  final String? returnedState;
}
