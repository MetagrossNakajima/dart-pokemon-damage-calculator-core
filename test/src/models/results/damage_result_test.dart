import '../../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/calculator_fixtures.dart' as calculator;

void main() {
  test(
    'level 50 integer reference rolls, percentages, trace and immutability',
    () {
      final r = calculator.damage();
      // floor(floor(22*40*100/100)/50)+2=19; floor(random), half-down STAB.
      expect(r.hits.single.rolls, [
        24,
        24,
        24,
        24,
        24,
        25,
        25,
        25,
        25,
        25,
        27,
        27,
        27,
        27,
        27,
        28,
      ]);
      expect(r.min, 24);
      expect(r.max, 28);
      expect(r.minPercent, 12);
      expect(r.maxPercent, 14);
      expect(r.distribution.totalWeight, BigInt.from(16));
      final h = r.hits.single;
      expect([h.power, h.attack, h.defense, h.critical], [40, 100, 100, false]);
      for (final t in h.trace) {
        expect(t.id, isNotEmpty);
        expect(ModifierStage.values, contains(t.stage));
        expect(t.denominator, greaterThan(0));
        expect(t.numerator, greaterThanOrEqualTo(0));
        expect(t.before, greaterThanOrEqualTo(0));
        expect(t.after, greaterThanOrEqualTo(0));
      }
      expect(() => r.hits.clear(), throwsUnsupportedError);
      expect(() => h.rolls.clear(), throwsUnsupportedError);
      expect(() => h.trace.clear(), throwsUnsupportedError);
      expect(() => r.distribution.weights.clear(), throwsUnsupportedError);
    },
  );
}
