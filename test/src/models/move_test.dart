import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;
import '../../support/input_adapter.dart' show moveId;

void main() {
  for (final detailed in [false, true]) {
    test('Moveの往復と値による等価性 / $detailed', () {
      domain.equality(
        valid(Move.fromDto(domain.move())),
        valid(Move.fromDto(domain.move())),
      );
    });
  }
  test('コレクションの等価性と不変性', () {
    final m = valid(Move.fromDto(domain.move()));
    final reordered = valid(
      Move.fromDto(
        MoveDto(
          id: moveId('BulletSeed'),
          type: PokemonType.grass,
          power: 25,
          category: Category.physical,
          flags: {MoveFlag.bullet, MoveFlag.contact},
        ),
      ),
    );
    expect(m, reordered);
    expect(m.hashCode, reordered.hashCode);
    expect(
      m,
      isNot(
        valid(
          Move.fromDto(
            MoveDto(
              id: moveId('BulletSeed'),
              type: PokemonType.grass,
              power: 25,
              category: Category.physical,
              flags: {MoveFlag.contact},
            ),
          ),
        ),
      ),
    );
    expect(
      m,
      isNot(
        valid(
          Move.fromDto(
            MoveDto(
              id: moveId('BulletSeed'),
              type: PokemonType.grass,
              power: 25,
              category: Category.physical,
              flags: {MoveFlag.sound, MoveFlag.contact},
            ),
          ),
        ),
      ),
    );
  });
}
