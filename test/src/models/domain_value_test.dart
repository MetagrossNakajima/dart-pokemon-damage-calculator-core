import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../support/value_objects_fixtures.dart' show valid;
import '../../support/domain_models_fixtures.dart' as domain;

void main() {
  test('異なるドメイン型は等しくない', () {
    final m = valid(Move.fromDto(domain.move()));
    final profile = valid(PokemonProfile.fromDto(domain.pokemon().profile));
    expect(m == profile, isFalse);
  });
}
