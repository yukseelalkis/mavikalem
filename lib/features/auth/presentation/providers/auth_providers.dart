import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mavikalem_app/core/di/providers.dart';
import 'package:mavikalem_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mavikalem_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mavikalem_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mavikalem_app/features/auth/domain/entities/oauth_authorization_request.dart';
import 'package:mavikalem_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mavikalem_app/features/auth/domain/usecases/exchange_code_for_token.dart';
import 'package:mavikalem_app/features/auth/domain/usecases/parse_oauth_redirect.dart';
import 'package:mavikalem_app/features/auth/domain/usecases/start_oauth_login.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio);
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthLocalDataSource(secureStorage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final local = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(remote, local);
});

final startOAuthLoginUseCaseProvider = Provider<StartOAuthLogin>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return StartOAuthLogin(repository);
});

final exchangeCodeForTokenUseCaseProvider = Provider<ExchangeCodeForToken>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return ExchangeCodeForToken(repository);
});

final parseOAuthRedirectUseCaseProvider = Provider<ParseOAuthRedirect>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ParseOAuthRedirect(repository);
});

final authStatusProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final token = await repository.getAccessToken();
  return token != null && token.isNotEmpty;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
      return AuthController(ref);
    });

enum AuthFlowStage { idle, openingWebView, exchangingToken, success, error }

class AuthControllerState {
  const AuthControllerState({
    required this.stage,
    this.errorMessage,
    this.request,
  });

  const AuthControllerState.idle() : this(stage: AuthFlowStage.idle);

  final AuthFlowStage stage;
  final String? errorMessage;
  final OAuthAuthorizationRequest? request;

  bool get isLoading =>
      stage == AuthFlowStage.openingWebView ||
      stage == AuthFlowStage.exchangingToken;

  AuthControllerState copyWith({
    AuthFlowStage? stage,
    String? errorMessage,
    OAuthAuthorizationRequest? request,
    bool clearError = false,
  }) {
    return AuthControllerState(
      stage: stage ?? this.stage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      request: request ?? this.request,
    );
  }
}

final class AuthController extends StateNotifier<AuthControllerState> {
  AuthController(this._ref) : super(const AuthControllerState.idle());

  final Ref _ref;

  OAuthAuthorizationRequest prepareOAuthRequest() {
    final startLogin = _ref.read(startOAuthLoginUseCaseProvider);
    final request = startLogin();
    state = state.copyWith(
      stage: AuthFlowStage.openingWebView,
      request: request,
      clearError: true,
    );
    return request;
  }

  Future<void> completeLoginWithRedirect(Uri redirectUri) async {
    state = state.copyWith(
      stage: AuthFlowStage.exchangingToken,
      clearError: true,
    );

    try {
      final repository = _ref.read(authRepositoryProvider);
      final exchangeToken = _ref.read(exchangeCodeForTokenUseCaseProvider);
      final parseRedirect = _ref.read(parseOAuthRedirectUseCaseProvider);

      final expectedState = state.request?.state;
      if (expectedState == null || expectedState.isEmpty) {
        throw StateError('OAuth state bulunamadi. Akisi tekrar baslatin.');
      }

      final payload = parseRedirect(redirectUri, expectedState: expectedState);

      final token = await exchangeToken(payload.code);
      await repository.saveToken(token);
      _ref.invalidate(authStatusProvider);

      state = state.copyWith(stage: AuthFlowStage.success, clearError: true);
    } catch (error) {
      state = state.copyWith(
        stage: AuthFlowStage.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> logout() async {
    final repository = _ref.read(authRepositoryProvider);
    await repository.logout();
    _ref.invalidate(authStatusProvider);
    state = const AuthControllerState.idle();
  }

  void resetIdle() {
    state = state.copyWith(stage: AuthFlowStage.idle, clearError: true);
  }
}
