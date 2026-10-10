import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;

void main() {
  test('コレクションの等価性と不変性', () {
    final a = valid(DamageWeights.create({0: BigInt.one, 20: BigInt.two}));
    final b = valid(DamageWeights.create({20: BigInt.two, 0: BigInt.one}));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(valid(DamageWeights.create({0: BigInt.one}))));
    expect(
      a,
      isNot(valid(DamageWeights.create({1: BigInt.one, 20: BigInt.two}))),
    );
    expect(
      a,
      isNot(valid(DamageWeights.create({0: BigInt.two, 20: BigInt.two}))),
    );

    expect(() => a.weights.clear(), throwsUnsupportedError);
  });
}
