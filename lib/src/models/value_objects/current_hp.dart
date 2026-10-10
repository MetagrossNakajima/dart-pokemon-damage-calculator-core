// 現在HP
part of '../value_objects.dart';

final class CurrentHp extends Value<int> {
  const CurrentHp._(super.value) : super._();
  static Validation<CurrentHp> create(int value) => value > 0
      ? Valid(CurrentHp._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
