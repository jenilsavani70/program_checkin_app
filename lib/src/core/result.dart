enum FailureKind {
  timeout,
  offline,
  malformedJson,
  unauthorized,
  rateLimited,
  validation,
  unknown,
}

class AppFailure {
  const AppFailure({
    required this.kind,
    required this.safeCode,
    required this.retryable,
  });

  final FailureKind kind;
  final String safeCode;
  final bool retryable;

  bool get clearsSession => kind == FailureKind.unauthorized;
}

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>(:final value) => success(value),
      Failure<T>(failure: final error) => failure(error),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}
