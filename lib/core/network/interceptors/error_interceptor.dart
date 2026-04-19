import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mavikalem_app/core/error/failures.dart';

final class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final responseData = err.response?.data;
    final message =
        responseData?.toString() ?? err.message ?? 'Bilinmeyen hata';

    if (statusCode == 400) {
      final request = err.requestOptions;
      debugPrint(
        'HTTP 400 -> ${request.method} ${request.baseUrl}${request.path}'
        '\nQuery: ${request.queryParameters}'
        '\nBody: ${request.data}'
        '\nResponse: ${_prettyJson(responseData)}',
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: AuthFailure('Yetkisiz istek: $message'),
          response: err.response,
          type: err.type,
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: NetworkFailure('Ag hatasi ($statusCode): $message'),
        response: err.response,
        type: err.type,
      ),
    );
  }

  String _prettyJson(dynamic data) {
    if (data == null) return 'null';
    if (data is Map<String, dynamic> || data is List<dynamic>) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    return data.toString();
  }
}
