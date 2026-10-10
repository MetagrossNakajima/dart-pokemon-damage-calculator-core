import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<DamageAmount, int>(
    'DamageAmount',
    DamageAmount.create,
    [0, 1000000000],
    [-1],
    ValidationCode.outOfRange,
  );
}
