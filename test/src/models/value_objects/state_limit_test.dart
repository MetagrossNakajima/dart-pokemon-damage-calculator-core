import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<StateLimit, int>(
    'StateLimit',
    StateLimit.create,
    [1, 1000000000],
    [0, -1],
    ValidationCode.outOfRange,
  );
}
