import 'package:test/test.dart';
import '../../../support/input_adapter.dart' as adapter;
import '../../../support/value_objects_fixtures.dart' as values;
import '../../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import '../../../support/calculator_fixtures.dart' as calculator;
import '../../../support/effects_fixtures.dart' as effects;

void main() {
  {
    values.cases<MovePriority, int>(
      'MovePriority',
      MovePriority.create,
      [-7, 5],
      [-8, 6],
      ValidationCode.outOfRange,
    );
  }
  {
    test('priority ranges are validated', () {
      for (final priority in [-8, 6]) {
        calculator.failure(
          adapter.calculateDamage(
            DamageRequestDto(
              attacker: effects.p(),
              defender: effects.p(),
              move: MoveDto(
                id: moveId('Tackle'),
                type: PokemonType.normal,
                power: 40,
                category: Category.physical,
                priority: priority,
              ),
              field: effects.f(),
            ),
          ),
          adapter.FailureKind.invalidInput,
        );
      }
    });
  }
}
