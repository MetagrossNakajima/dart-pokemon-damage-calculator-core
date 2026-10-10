import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  test('profile rejects sub-tenth weights before calculating damage', () {
    for (final weight in [0.01, 99.95, 49.99]) {
      final input = PokemonProfileDto(
        id: PokemonId.pikachu,
        types: [PokemonType.normal],
        weight: weight,
      );
      final result = PokemonProfile.fromDto(input);
      expect(result, isA<Invalid<PokemonProfile>>());
      expect((result as Invalid<PokemonProfile>).errors, [
        const ValidationError(
          'pokemonProfile.weight',
          ValidationCode.outOfRange,
        ),
      ]);
    }
  });
  test('weight accepts every tenth of a kilogram without truncation', () {
    for (var hectograms = 1; hectograms < 10000; hectograms++) {
      final value = values.valid(PokemonWeight.create(hectograms / 10));
      expect(value.hectograms, hectograms);
      expect(value.value, hectograms / 10);
    }
  });
  values.cases<PokemonWeight, double>(
    'PokemonWeight',
    PokemonWeight.create,
    [0.1, 999.9],
    [
      0.0,
      0.01,
      0.099,
      0.11,
      9.99,
      99.99,
      99.95,
      49.99,
      999.99,
      -1.0,
      1000.0,
      100001.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ],
    ValidationCode.outOfRange,
  );
}
