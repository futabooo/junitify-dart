/// A type that represents either success or failure.
///
/// [Success] contains a value of type [T].
/// [Failure] contains an error of type [E].
sealed class Result<T, E> {
  const Result();

  /// Returns true if this result is a success.
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this result is a failure.
  bool get isFailure => this is Failure<T, E>;

  /// Returns the success value or null.
  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    Failure() => null,
  };

  /// Returns the error or null.
  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(error: final e) => e,
  };

  /// Maps the success value using the given function.
  Result<R, E> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(value: final v) => Success(transform(v)),
      Failure(error: final e) => Failure(e),
    };
  }

  /// Maps the error using the given function.
  Result<T, F> mapError<F>(F Function(E error) transform) {
    return switch (this) {
      Success(value: final v) => Success(v),
      Failure(error: final e) => Failure(transform(e)),
    };
  }

  /// Chains another Result-returning operation.
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) {
    return switch (this) {
      Success(value: final v) => transform(v),
      Failure(error: final e) => Failure(e),
    };
  }
}

/// Represents a successful result containing a value.
final class Success<T, E> extends Result<T, E> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T, E> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Represents a failed result containing an error.
final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);

  final E error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Failure<T, E> && error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
