// 分布の整数重み
part of '../value_objects.dart';

final class DistributionWeight extends Value<BigInt> {
  const DistributionWeight._(super.value) : super._();
  static Validation<DistributionWeight> create(BigInt value) =>
      value > BigInt.zero
      ? Valid(DistributionWeight._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);
}
