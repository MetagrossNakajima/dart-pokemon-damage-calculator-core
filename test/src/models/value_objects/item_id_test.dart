import 'dart:convert';
import 'dart:io';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../../../support/value_objects_fixtures.dart' show valid;
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  {
    final source =
        jsonDecode(File('data/known_ids.json').readAsStringSync()) as Map;

    void check<T extends Value<String>>(
      String kind,
      List<T> values,
      Validation<T> Function(String) create,
    ) {
      test(
        '$kind known IDs preserve every source string and equal created IDs',
        () {
          expect(values.map((v) => v.value).toList(), source[kind]);
          for (final value in values) {
            final recreated = valid(create(value.value));
            expect(recreated, value);
            expect(recreated.hashCode, value.hashCode);
          }
          expect(() => values.clear(), throwsUnsupportedError);
        },
      );
      test('$kind accepts unknown exact strings and rejects empty strings', () {
        for (final text in [
          'Future-ID_α',
          'future-id_α',
          ' ',
          'ChoiceItem',
          'TypePlate',
        ]) {
          expect(valid(create(text)).value, text);
        }
        expect(valid(create('Future-ID')), isNot(valid(create('future-id'))));
        expect(create(''), isA<Invalid<T>>());
      });
    }

    check('item', ItemId.knownValues, ItemId.create);
  }
  {
    values.cases<ItemId, String>(
      'ItemId',
      ItemId.create,
      ['UtilityUmbrella', 'custom'],
      [''],
      ValidationCode.required,
    );
  }
}
