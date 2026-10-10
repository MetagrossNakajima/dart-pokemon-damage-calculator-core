import 'package:test/test.dart';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

void main() {
  test('huge exact probability weights stay finite', () {
    final w = BigInt.one << 2000;
    for (final (numerator, denominator, expected) in [
      (BigInt.zero, w, 0.0),
      (w, w, 1.0),
      (w, w * BigInt.two, 0.5),
      (w, w * BigInt.from(3), 1 / 3),
      (w * BigInt.from(7), w * BigInt.from(10), 0.7),
      (w, w * (BigInt.one << 1000), 9.332636185032189e-302),
      (w, w * (BigInt.one << 1074), 5e-324),
      (w, w * (BigInt.one << 1075), 0.0),
      (w * BigInt.from(3), w * (BigInt.one << 1075), 1e-323),
    ]) {
      final p = KnockoutProbability(numerator, denominator);
      expect(p.probability, expected);
      expect(p.probability.isFinite, isTrue);
      expect(p.weight, numerator);
      expect(p.totalWeight, denominator);
    }
  });

  test('probability rounds a halfway significand to the even double', () {
    final denominator = BigInt.one << 54;
    expect(
      KnockoutProbability(
        (BigInt.one << 53) + BigInt.one,
        denominator,
      ).probability,
      0.5,
    );
    expect(
      KnockoutProbability(
        (BigInt.one << 53) + BigInt.from(3),
        denominator,
      ).probability,
      0.5000000000000002,
    );
  });
}
