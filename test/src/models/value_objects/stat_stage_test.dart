import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<StatStage, int>(
    'StatStage',
    StatStage.create,
    [-6, 0, 6],
    [-7, 7],
    ValidationCode.outOfRange,
  );
}
