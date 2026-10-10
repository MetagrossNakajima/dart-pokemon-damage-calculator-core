// 現在HP
part of '../value_objects.dart';

final class CurrentHp extends Value<int> {
  const CurrentHp._(super.value) : super._();
  static Validation<CurrentHp> create(int value) => value >= 1 && value <= 999
      ? Valid(CurrentHp._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
