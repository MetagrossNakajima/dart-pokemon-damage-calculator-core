import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<SpikesLayers, int>(
    'SpikesLayers',
    SpikesLayers.create,
    [0, 3],
    [-1, 4],
    ValidationCode.outOfRange,
  );
}
