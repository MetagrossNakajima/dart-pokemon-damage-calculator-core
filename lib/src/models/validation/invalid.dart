part of '../validation.dart';

/// 1件以上の不変な検証エラーを持つ、生成失敗の結果。
final class Invalid<T> extends Validation<T> {
  Invalid(Iterable<ValidationError> errors)
    : errors = List.unmodifiable(errors) {
    if (this.errors.isEmpty) {
      throw ArgumentError.value(errors, 'errors', 'Must not be empty');
    }
  }
  final List<ValidationError> errors;
}
