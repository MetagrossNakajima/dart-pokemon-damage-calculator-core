import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<CudChewTurn, int>(
    'CudChewTurn',
    CudChewTurn.create,
    [-100, 0, 100],
    [],
    ValidationCode.outOfRange,
  );
}
