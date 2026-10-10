import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<MovePower, int>(
    'MovePower',
    MovePower.create,
    [0, 250, 1000],
    [-1, 1001],
    ValidationCode.outOfRange,
  );
}
