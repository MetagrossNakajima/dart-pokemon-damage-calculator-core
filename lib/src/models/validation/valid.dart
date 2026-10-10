part of '../validation.dart';

/// 不変条件を検証し、生成に成功した値。
final class Valid<T> extends Validation<T> {
  const Valid(this.value);
  final T value;
}
