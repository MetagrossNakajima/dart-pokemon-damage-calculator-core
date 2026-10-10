// ダメージ量
part of '../value_objects.dart';

final class DamageAmount extends Value<int> {
  const DamageAmount._(super.value) : super._();
  static Validation<DamageAmount> create(int value) => value >= 0
      ? Valid(DamageAmount._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
