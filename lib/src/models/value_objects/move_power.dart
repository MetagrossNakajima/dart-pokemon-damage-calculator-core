// 技の基本威力
part of '../value_objects.dart';

final class MovePower extends Value<int> {
  const MovePower._(super.value) : super._();
  static Validation<MovePower> create(int value) => value >= 0 && value <= 1000
      ? Valid(MovePower._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
