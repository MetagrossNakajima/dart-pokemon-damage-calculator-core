// ひんしになった味方の数
part of '../value_objects.dart';

final class FaintedAllies extends Value<int> {
  const FaintedAllies._(super.value) : super._();
  static Validation<FaintedAllies> create(int value) =>
      value >= 0 && value <= 100
      ? Valid(FaintedAllies._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
