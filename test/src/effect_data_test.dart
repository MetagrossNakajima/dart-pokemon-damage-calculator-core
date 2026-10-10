import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../support/effects_fixtures.dart' as effects;

void main() {
  test(
    'real choice items and plates apply while virtual item IDs have no effect',
    () {
      final base = effects.hit();
      for (final id in ['ChoiceItem', 'TypePlate']) {
        final actual = effects.hit(a: effects.p(item: id));
        expect(actual.rolls, base.rolls);
        expect(actual.attack, 100);
        expect(actual.power, 40);
      }
      final band = effects.hit(a: effects.p(item: 'ChoiceBand'));
      expect(band.attack, 150);
      expect(band.rolls.last, greaterThan(base.rolls.last));
      final specs = effects.hit(
        a: effects.p(item: 'ChoiceSpecs'),
        move: effects.m(category: Category.special),
      );
      expect(specs.attack, 150);
      final plate = effects.hit(
        a: effects.p(item: 'FlamePlate'),
        move: effects.m(type: 'Fire'),
      );
      expect(plate.power, 48);
    },
  );
}
