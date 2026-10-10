part of '../value_objects.dart';

/// 0〜100の整数で表す命中率。
final class AccuracyPercent extends Value<int> {
  const AccuracyPercent._(super.value) : super._();

  static Validation<AccuracyPercent> create(int value) =>
      value >= 0 && value <= 100
      ? Valid(AccuracyPercent._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
