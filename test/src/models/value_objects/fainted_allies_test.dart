import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<FaintedAllies, int>(
    'FaintedAllies',
    FaintedAllies.create,
    [0, 100],
    [-1, 101],
    ValidationCode.outOfRange,
  );
}
