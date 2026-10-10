// 体重
part of '../value_objects.dart';

final class PokemonWeight extends Value<double> {
  const PokemonWeight._(super.value) : super._();
  static Validation<PokemonWeight> create(double value) =>
      value.isFinite &&
          value >= 0.1 &&
          value < 1000 &&
          (value * 10).round() / 10 == value
      ? Valid(PokemonWeight._(value))
      : Invalid([const ValidationError('value', ValidationCode.outOfRange)]);

  /// 体重を0.1kg単位で表す整数値。
  int get hectograms => (value * 10).round();
}
