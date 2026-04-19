sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
