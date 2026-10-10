// 猛毒カウンター
part of '../value_objects.dart';

final class ToxicCounter extends Value<int> {
  const ToxicCounter._(super.value) : super._();
  static Validation<ToxicCounter> create(int value) => value >= 1 && value <= 15
      ? Valid(ToxicCounter._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
