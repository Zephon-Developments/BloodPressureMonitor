/// Result pattern for operations that can fail.
///
/// Use this type to explicitly handle success and failure cases without throwing exceptions.
/// This provides better type safety and forces callers to handle errors explicitly.
///
/// Example:
/// ```dart
/// final result = await saveReading(reading);
/// switch (result) {
///   case Success(:final value):
///     print('Saved: $value');
///   case Failure(:final error):
///     print('Error: ${error.message}');
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Successful result containing a value.
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

/// Failed result containing an error.
class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

/// Application error types for consistent error handling.
class AppError {
  final AppErrorType type;
  final String message;
  final dynamic debugInfo;

  const AppError({
    required this.type,
    required this.message,
    this.debugInfo,
  });

  /// User-friendly message suitable for display in the UI.
  String get userMessage {
    switch (type) {
      case AppErrorType.database:
        return 'Unable to save data. Please try again.';
      case AppErrorType.fileSystem:
        return 'File operation failed. Please check permissions and try again.';
      case AppErrorType.validation:
        return 'Invalid data format. Please check your file and try again.';
      case AppErrorType.notFound:
        return 'The requested resource was not found.';
      case AppErrorType.unexpected:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Database operation error.
  factory AppError.database(String message, [dynamic debugInfo]) {
    return AppError(
      type: AppErrorType.database,
      message: message,
      debugInfo: debugInfo,
    );
  }

  /// File system operation error.
  factory AppError.fileSystem(String message, [dynamic debugInfo]) {
    return AppError(
      type: AppErrorType.fileSystem,
      message: message,
      debugInfo: debugInfo,
    );
  }

  /// Validation error.
  factory AppError.validation(String message, [dynamic debugInfo]) {
    return AppError(
      type: AppErrorType.validation,
      message: message,
      debugInfo: debugInfo,
    );
  }

  /// Resource not found error.
  factory AppError.notFound(String message, [dynamic debugInfo]) {
    return AppError(
      type: AppErrorType.notFound,
      message: message,
      debugInfo: debugInfo,
    );
  }

  /// Unexpected/unknown error.
  factory AppError.unexpected([String? message, dynamic debugInfo]) {
    return AppError(
      type: AppErrorType.unexpected,
      message: message ?? 'An unexpected error occurred',
      debugInfo: debugInfo,
    );
  }

  @override
  String toString() => '$type: $message';
}

/// Error type enumeration.
enum AppErrorType {
  database,
  fileSystem,
  validation,
  notFound,
  unexpected,
}
