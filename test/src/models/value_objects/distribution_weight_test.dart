import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../../support/value_objects_fixtures.dart' as values;

void main() {
  values.cases<DistributionWeight, BigInt>(
    'DistributionWeight',
    DistributionWeight.create,
    [BigInt.one, BigInt.from(1000000)],
    [BigInt.zero, -BigInt.one],
    ValidationCode.outOfRange,
  );
}
