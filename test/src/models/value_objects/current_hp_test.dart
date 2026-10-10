import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<CurrentHp, int>(
    'CurrentHp',
    CurrentHp.create,
    [1, 10000, 10001, 1000000],
    [0, -1],
    ValidationCode.outOfRange,
  );
}
