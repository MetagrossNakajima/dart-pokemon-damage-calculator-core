// ターン番号
part of '../value_objects.dart';

final class TurnNumber extends Value<int> {
  const TurnNumber._(super.value) : super._();
  static Validation<TurnNumber> create(int value) => value >= 1
      ? Valid(TurnNumber._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
