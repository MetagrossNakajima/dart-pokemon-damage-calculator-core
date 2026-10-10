import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<ToxicCounter, int>(
    'ToxicCounter',
    ToxicCounter.create,
    [1, 15],
    [0, 16],
    ValidationCode.outOfRange,
  );
}
