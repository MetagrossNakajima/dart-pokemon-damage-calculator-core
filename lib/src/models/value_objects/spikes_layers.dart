// まきびしの層数
part of '../value_objects.dart';

final class SpikesLayers extends Value<int> {
  const SpikesLayers._(super.value) : super._();
  static Validation<SpikesLayers> create(int value) => value >= 0 && value <= 3
      ? Valid(SpikesLayers._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
