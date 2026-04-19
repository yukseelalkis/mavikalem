import 'dart:math';

import 'package:dio/dio.dart';
import 'package:mavikalem_app/core/constants/api_endpoints.dart';
import 'package:mavikalem_app/core/constants/oauth_config.dart';
import 'package:mavikalem_app/core/error/failures.dart';
import 'package:mavikalem_app/core/network/api_response_parser.dart';
import 'package:mavikalem_app/features/auth/data/models/token_response_model.dart';
import 'package:mavikalem_app/features/auth/domain/entities/oauth_authorization_request.dart';
import 'package:mavikalem_app/features/auth/domain/entities/oauth_redirect_payload.dart';

final class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  OAuthAuthorizationRequest buildAuthorizationRequest() {
    final state = _createState();
    final url = Uri.parse(ApiEndpoints.authAuthorize).replace(
      queryParameters: <String, String>{
        'response_type': 'code',
        'client_id': OAuthConfig.clientId,
        'redirect_uri': OAuthConfig.redirectUri,
        'state': state,
      },
    );

    return OAuthAuthorizationRequest(url: url, state: state);
  }

  OAuthRedirectPayload extractCodeFromRedirect(
    Uri callbackUri, {
    required String expectedState,
  }) {
    final error = callbackUri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      final description =
          callbackUri.queryParameters['error_description'] ?? error;
      throw AuthFailure('OAuth hatasi: $description');
    }

    final callbackState = callbackUri.queryParameters['state'];
    if (callbackState == null || callbackState != expectedState) {
      throw const AuthFailure('OAuth state dogrulamasi basarisiz.');
    }

    final code = callbackUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const AuthFailure(
        'OAuth callback icinde code parametresi bulunamadi.',
      );
    }
    return OAuthRedirectPayload(code: code, returnedState: callbackState);
  }

  String _createState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(36));
    return values
        .map(
          (value) =>
              value < 10 ? value.toString() : String.fromCharCode(87 + value),
        )
        .join();
  }

  Future<TokenResponseModel> exchangeCodeForToken(String code) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.authToken,
      data: <String, dynamic>{
        'grant_type': 'authorization_code',
        'client_id': OAuthConfig.clientId,
        'client_secret': OAuthConfig.clientSecret,
        'redirect_uri': OAuthConfig.redirectUri,
        'code': code,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: <String, String>{'Accept': 'application/json'},
      ),
    );

    final json = ApiResponseParser.parseMap(response.data);
    final model = TokenResponseModel.fromJson(json);
    if (model.accessToken.isEmpty) {
      throw const AuthFailure('Token cevabinda access_token bulunamadi.');
    }
    return model;
  }
}
