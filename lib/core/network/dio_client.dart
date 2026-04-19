import 'package:dio/dio.dart';
import 'package:mavikalem_app/core/constants/api_endpoints.dart';
import 'package:mavikalem_app/core/network/interceptors/auth_interceptor.dart';
import 'package:mavikalem_app/core/network/interceptors/error_interceptor.dart';
import 'package:mavikalem_app/core/storage/secure_storage_service.dart';

final class DioClient {
  DioClient(this._secureStorageService);

  final SecureStorageService _secureStorageService;

  Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll(<Interceptor>[
      AuthInterceptor(_secureStorageService),
      ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: false),
    ]);
    return dio;
  }
}
