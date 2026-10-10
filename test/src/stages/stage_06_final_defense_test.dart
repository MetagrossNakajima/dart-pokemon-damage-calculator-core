import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import '../../support/effects_fixtures.dart' as effects;
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

void main() {
  test('sandstorm special defense uses the defender tera type', () {
    final result = effects.hit(
      d: effects.p(types: ['Normal'], tera: 'Rock'),
      move: effects.m(category: Category.special),
      field: effects.f(weather: Weather.sandstorm),
    );

    expect(result.defense, 150);
    expect(
      result.trace.singleWhere((entry) => entry.id == 'WeatherDefense').after,
      150,
    );
  });
}
