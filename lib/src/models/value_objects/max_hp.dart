// 最大HP
part of '../value_objects.dart';

final class MaxHp extends Value<int> {
  const MaxHp._(super.value) : super._();
  static Validation<MaxHp> create(int value) => value >= 1 && value <= 999
      ? Valid(MaxHp._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
