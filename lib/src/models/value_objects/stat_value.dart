// 能力の実数値
part of '../value_objects.dart';

final class StatValue extends Value<int> {
  const StatValue._(super.value) : super._();
  static Validation<StatValue> create(int value) => value > 0
      ? Valid(StatValue._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
