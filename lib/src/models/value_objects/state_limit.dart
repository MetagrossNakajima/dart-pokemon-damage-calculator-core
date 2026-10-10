// 分布状態数の制限
part of '../value_objects.dart';

final class StateLimit extends Value<int> {
  const StateLimit._(super.value) : super._();
  static Validation<StateLimit> create(int value) => value > 0
      ? Valid(StateLimit._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
