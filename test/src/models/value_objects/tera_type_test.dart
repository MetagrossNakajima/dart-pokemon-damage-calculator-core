import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  test('通常タイプとStellarの範囲を区別する', () {
    for (final type in PokemonType.values) {
      expect(values.valid(PokemonType.create(type.id)), type);
      final tera = values.valid(TeraType.create(type.id));
      expect(tera, TeraType.of(type));
      expect(tera.value, type.id);
      expect(tera.hashCode, TeraType.of(type).hashCode);
    }
    expect(PokemonType.create('Stellar'), isA<Invalid<PokemonType>>());
    expect(PokemonType.create('normal'), isA<Invalid<PokemonType>>());
    expect(values.valid(TeraType.create('Stellar')), TeraType.stellar);
    expect(TeraType.create('unknown'), isA<Invalid<TeraType>>());
    for (final terrain in Terrain.values) {
      expect(values.valid(Terrain.create(terrain.name)), terrain);
    }
    expect(Terrain.create('Electric'), isA<Invalid<Terrain>>());
  });
}
