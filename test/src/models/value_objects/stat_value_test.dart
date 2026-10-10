import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<StatValue, int>(
    'StatValue',
    StatValue.create,
    [1, 998, 999],
    [-1, 0, 1000, 32768, 65536, 9223372036854775807],
    ValidationCode.outOfRange,
  );
}
