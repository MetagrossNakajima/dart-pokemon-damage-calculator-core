import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import '../../support/pokemon_patch.dart';
import 'package:test/test.dart';
import '../../support/effects_fixtures.dart' as effects;
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

void main() {
  for (final c in [
    ('BeadsofRuin', Category.special, FieldEffect.beadsOfRuin),
    ('SwordofRuin', Category.physical, FieldEffect.swordOfRuin),
  ]) {
    test('ruin defense $c', () {
      expect(
        effects
            .hit(
              a: effects.p(ability: c.$1),
              move: effects.m(category: c.$2),
            )
            .defense,
        75,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: c.$1),
              d: effects.p(ability: c.$1),
              move: effects.m(category: c.$2),
            )
            .defense,
        100,
      );
      expect(
        effects
            .hit(
              move: effects.m(category: c.$2),
              field: effects.f(effects: {c.$3}),
            )
            .defense,
        75,
      );
    });
  }

  final defenseCases = [
    (
      'FlowerGift',
      150,
      effects.p(ability: 'FlowerGift'),
      effects.m(category: Category.special),
      effects.f(weather: Weather.sunlight),
    ),
    (
      'MarvelScale',
      150,
      effects.p(ability: 'MarvelScale', status: Status.poison),
      effects.m(),
      effects.f(),
    ),
    (
      'GrassPelt',
      150,
      effects.p(ability: 'GrassPelt'),
      effects.m(),
      effects.f(terrain: Terrain.grass),
    ),
    ('FurCoat', 200, effects.p(ability: 'FurCoat'), effects.m(), effects.f()),
    (
      'Eviolite',
      150,
      effects.p(item: 'Eviolite', flags: {PokemonFlag.canEvolve: true}),
      effects.m(),
      effects.f(),
    ),
    (
      'DeepSeaScale',
      200,
      effects.p(id: 'Clamperl', item: 'DeepSeaScale'),
      effects.m(category: Category.special),
      effects.f(),
    ),
    (
      'MetalPowder',
      200,
      effects.p(id: 'Ditto', item: 'MetalPowder'),
      effects.m(),
      effects.f(),
    ),
  ];

  for (final c in defenseCases) {
    test('defense ${c.$1}', () {
      expect(effects.hit(d: c.$3, move: c.$4, field: c.$5).defense, c.$2);
      final plain = PokemonPatch(
        ability: const Replacement(null),
        item: const Replacement(null),
      ).apply(c.$3);
      expect(effects.hit(d: plain, move: c.$4, field: c.$5).defense, 100);
    });
  }

  test('evolution and transformation are checked', () {
    expect(effects.hit(d: effects.p(item: 'Eviolite')).defense, 100);
    expect(
      effects
          .hit(
            d: effects.p(
              id: 'Ditto',
              item: 'MetalPowder',
              flags: {PokemonFlag.transformed: true},
            ),
          )
          .defense,
      100,
    );
  });
}
