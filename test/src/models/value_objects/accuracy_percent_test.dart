import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<AccuracyPercent, int>(
    'AccuracyPercent',
    AccuracyPercent.create,
    [0, 75, 100],
    [-1, 101],
    ValidationCode.outOfRange,
  );
}
