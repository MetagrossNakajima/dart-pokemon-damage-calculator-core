import 'package:test/test.dart';
import '../../support/calculator_fixtures.dart' as calculator;
import '../../support/effects_fixtures.dart' as effects;

void main() {
  for (final id in ['DoubleHit', 'ArmThrust', 'PopulationBomb']) {
    test('multi-hit move $id returns one specified hit', () {
      final result = calculator.damage(m: effects.m(id: id));
      expect(result.hits, hasLength(1));
      expect(result.distribution.totalWeight, BigInt.from(16));
      expect(result.min, 24);
      expect(result.max, 28);
    });
  }
}
