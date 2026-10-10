import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../support/calculator_fixtures.dart' as calculator;

void main() {
  for (var rank = -6; rank <= 6; rank++) {
    test('rank boundary $rank', () {
      final h = calculator
          .damage(
            a: calculator.pokemon(ranks: {Stat.atk: rank}),
            d: calculator.pokemon(ranks: {Stat.def: rank}),
          )
          .hits
          .single;
      final expected = rank < 0 ? 200 ~/ (2 - rank) : 100 * (2 + rank) ~/ 2;
      expect(h.attack, expected);
      expect(h.defense, expected);
    });
  }

  test('ordering and fixed point rounding at half boundaries', () {
    final r = calculator.damage(
      a: calculator.pokemon(item: 'LifeOrb'),
      d: calculator.pokemon(
        ability: 'Multiscale',
        item: 'ChilanBerry',
        reflect: true,
      ),
    );
    // chain(2048,2048,5324,2048) = 666; half-down(28*666/4096) = 5.
    expect(r.max, 5);
    expect(
      r.hits.single.trace.lastWhere((t) => t.id == 'FinalModifiers').numerator,
      666,
    );
    final h = calculator
        .damage(
          a: calculator.pokemon(
            stat: 101,
            ranks: {Stat.atk: -1},
            item: 'ChoiceBand',
          ),
        )
        .hits
        .single;
    expect(h.attack, 100); // floor(101*2/3)=67; 67*1.5=100.5 -> 100.
    expect(
      calculator.damage(a: calculator.pokemon(ability: 'Adaptability')).max,
      38,
    );
    expect(
      calculator.damage(a: calculator.pokemon(status: Status.burn)).max,
      14,
    );
  });
}
