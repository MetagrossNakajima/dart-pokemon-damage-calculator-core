// 能力ランク
part of '../value_objects.dart';

final class StatStage extends Value<int> {
  const StatStage._(super.value) : super._();
  static Validation<StatStage> create(int value) => value >= -6 && value <= 6
      ? Valid(StatStage._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
