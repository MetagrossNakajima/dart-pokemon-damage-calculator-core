import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;
import '../../support/input_adapter.dart' show pokemonId;

void main() {
  for (final detailed in [false, true]) {
    test('PokemonProfileの往復と値による等価性 / $detailed', () {
      final p = domain.pokemon(detailed: detailed);
      domain.equality(
        valid(PokemonProfile.fromDto(p.profile)),
        valid(PokemonProfile.fromDto(p.profile)),
      );
    });
  }
  test('コレクションの等価性と不変性', () {
    final profile = valid(PokemonProfile.fromDto(domain.pokemon().profile));
    expect(() => profile.types.clear(), throwsUnsupportedError);
    expect(
      profile,
      isNot(
        valid(
          PokemonProfile.fromDto(
            PokemonProfileDto(
              id: pokemonId('test'),
              types: [PokemonType.normal],
              weight: 50,
            ),
          ),
        ),
      ),
    );
    expect(
      profile,
      isNot(
        valid(
          PokemonProfile.fromDto(
            PokemonProfileDto(
              id: pokemonId('test'),
              types: [PokemonType.normal, PokemonType.fire],
              weight: 50,
            ),
          ),
        ),
      ),
    );
  });
}
