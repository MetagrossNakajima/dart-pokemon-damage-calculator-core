// 攻撃を受けた回数
part of '../value_objects.dart';

final class TimesHit extends Value<int> {
  const TimesHit._(super.value) : super._();
  static Validation<TimesHit> create(int value) => value >= 0 && value <= 100
      ? Valid(TimesHit._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
