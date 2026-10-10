// 技の優先度
part of '../value_objects.dart';

final class MovePriority extends Value<int> {
  const MovePriority._(super.value) : super._();
  static Validation<MovePriority> create(int value) => value >= -7 && value <= 5
      ? Valid(MovePriority._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
