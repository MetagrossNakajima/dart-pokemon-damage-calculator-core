import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../support/calculator_fixtures.dart' as calculator;
import '../support/pokemon_patch.dart';

void main() {
  for (final ability in ['Protean', 'Libero']) {
    test('$ability automatically applies move type STAB', () {
      final move = calculator.move(
        id: 'Flamethrower',
        type: 'Fire',
        power: 90,
        category: Category.special,
      );
      final ordinary = calculator.damage(m: move);
      final changed = calculator.damage(
        a: calculator.pokemon(types: ['Water'], ability: ability),
        m: move,
      );
      final fire = calculator.damage(
        a: calculator.pokemon(types: ['Fire']),
        m: move,
      );
      // Smogon cf95cb685b6cbbda1ea5f9dc783f62e3c3e3e900 / Gen 9。
      expect(changed.hits.single.rolls, [
        51,
        52,
        52,
        54,
        54,
        54,
        55,
        55,
        57,
        57,
        57,
        58,
        58,
        60,
        60,
        61,
      ]);
      expect(changed.hits.single.rolls, fire.hits.single.rolls);
      expect(changed.max, greaterThan(ordinary.max));
      final alreadyChanged = calculator.damage(
        a: calculator.pokemon(types: ['Water'], ability: ability),
        m: move,
      );
      expect(alreadyChanged.hits.single.rolls, fire.hits.single.rolls);
      final matching = calculator.damage(
        a: calculator.pokemon(types: ['Fire'], ability: ability),
        m: move,
      );
      expect(matching.hits.single.rolls, fire.hits.single.rolls);
      final incoming = calculator.move(type: 'Water');
      final defender = calculator.damage(
        d: calculator.pokemon(types: ['Fire'], ability: ability),
        m: incoming,
      );
      final plain = calculator.damage(
        d: calculator.pokemon(types: ['Fire']),
        m: incoming,
      );
      expect(defender.hits.single.rolls, plain.hits.single.rolls);
      final tera = calculator.damage(
        a: PokemonPatch(
          teraType: const Replacement(TeraType.water),
        ).apply(calculator.pokemon(types: ['Fire'], ability: ability)),
        m: move,
      );
      final plainTera = calculator.damage(
        a: PokemonPatch(
          teraType: const Replacement(TeraType.water),
        ).apply(calculator.pokemon(types: ['Fire'])),
        m: move,
      );
      expect(tera.hits.single.rolls, plainTera.hits.single.rolls);
    });
    test('$ability respects suppression and all tera types', () {
      final move = calculator.move(type: 'Fire');
      final ordinary = calculator.damage(m: move);
      final suppressed = calculator.damage(
        a: PokemonPatch(
          flags: const {PokemonFlag.abilitySuppressed: true},
        ).apply(calculator.pokemon(ability: ability)),
        m: move,
      );
      expect(suppressed.hits.single.rolls, ordinary.hits.single.rolls);
      final gas = calculator.damage(
        a: calculator.pokemon(ability: ability),
        d: calculator.pokemon(ability: 'NeutralizingGas'),
        m: move,
      );
      expect(gas.hits.single.rolls, ordinary.hits.single.rolls);
      for (final teraType in [
        TeraType.water,
        TeraType.fire,
        TeraType.stellar,
      ]) {
        final patch = PokemonPatch(teraType: Replacement(teraType));
        final changed = calculator.damage(
          a: patch.apply(calculator.pokemon(ability: ability)),
          m: move,
        );
        final plain = calculator.damage(
          a: patch.apply(calculator.pokemon()),
          m: move,
        );
        expect(changed.hits.single.rolls, plain.hits.single.rolls);
      }
    });
    test('$ability uses the transformed Weather Ball type', () {
      final move = calculator.move(id: 'WeatherBall', power: 50);
      final field = BattleFieldDto(
        format: BattleFormat.single,
        weather: Weather.sunlight,
      );
      final changed = calculator.damage(
        a: calculator.pokemon(types: ['Water'], ability: ability),
        m: move,
        f: field,
      );
      final fire = calculator.damage(
        a: calculator.pokemon(types: ['Fire']),
        m: move,
        f: field,
      );
      expect(changed.hits.single.rolls, fire.hits.single.rolls);
    });
  }
}
