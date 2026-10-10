import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<TurnNumber, int>(
    'TurnNumber',
    TurnNumber.create,
    [1, 1000],
    [0, -1],
    ValidationCode.outOfRange,
  );
}
