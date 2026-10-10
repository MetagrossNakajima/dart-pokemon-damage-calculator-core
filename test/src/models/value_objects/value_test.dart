import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../../support/value_objects_fixtures.dart' show valid;
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  {
    test('identical strings in different ID types remain distinct', () {
      final values = <Value<String>>[
        valid(PokemonId.create('same')),
        valid(MoveId.create('same')),
        valid(AbilityId.create('same')),
        valid(ItemId.create('same')),
      ];
      expect(values.toSet(), hasLength(4));
    });
  }
  {
    test('意味が異なる値は同じ整数でも等しくない', () {
      final stat = values.valid(StatValue.create(1));
      expect(stat, isNot(values.valid(CurrentHp.create(1))));
      expect(stat == (1 as Object), isFalse);
      expect(stat == (values.valid(MoveId.create('1')) as Object), isFalse);
    });
  }
}
