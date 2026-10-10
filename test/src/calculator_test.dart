import '../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../support/input_adapter.dart' as adapter;
import '../support/calculator_fixtures.dart' as calculator;
import '../support/value_objects_fixtures.dart' show valid;
import '../support/domain_models_fixtures.dart' as domain;

void main() {
  {
    test('typed input and support failures', () {
      for (final p in [
        calculator.pokemon(types: []),
        calculator.pokemon(types: []),
        calculator.pokemon(types: ['Normal', 'Normal']),
        calculator.pokemon(types: ['Fire', 'Water', 'Grass']),
        calculator.pokemon(stat: 0),
        calculator.pokemon(ranks: {Stat.atk: -7}),
        calculator.pokemon(ranks: {Stat.atk: 7}),
        calculator.pokemon(weight: double.nan),
        calculator.pokemon(weight: 0),
        calculator.pokemon(weight: 100001),
      ]) {
        calculator.failure(
          adapter.calculateDamage(
            DamageRequestDto(
              attacker: p,
              defender: calculator.pokemon(),
              move: calculator.move(),
              field: calculator.single,
            ),
          ),
          adapter.FailureKind.invalidInput,
        );
      }
      expect(
        calculator
            .damage(a: calculator.pokemon(ability: '???'))
            .distribution
            .weights,
        calculator.damage().distribution.weights,
      );
      expect(
        calculator
            .damage(a: calculator.pokemon(item: '???'))
            .distribution
            .weights,
        calculator.damage().distribution.weights,
      );
      expect(
        calculator.damage(m: calculator.move(id: 'Unknown')).max,
        calculator.damage().max,
      );
      for (final id in [
        'Counter',
        'Bide',
        'Comeuppance',
        'MirrorCoat',
        'MetalBurst',
        'Psywave',
      ]) {
        calculator.failure(
          adapter.calculateDamage(
            DamageRequestDto(
              attacker: calculator.pokemon(),
              defender: calculator.pokemon(),
              move: calculator.move(id: id),
              field: calculator.single,
            ),
          ),
          adapter.FailureKind.unsupported,
        );
      }
      for (final power in [0, 1001]) {
        calculator.failure(
          adapter.calculateDamage(
            DamageRequestDto(
              attacker: calculator.pokemon(),
              defender: calculator.pokemon(),
              move: calculator.move(power: power),
              field: calculator.single,
            ),
          ),
          adapter.FailureKind.invalidInput,
        );
      }
      calculator.failure(
        adapter.calculateCombinedDamage(
          CombinedDamageRequestDto(
            attacks: [],
            setup: BattleSetupDto.none,
            defender: calculator.pokemon(),
            field: calculator.single,
          ),
        ),
        adapter.FailureKind.invalidInput,
      );
    });
  }
  {
    test('未対応の技は入力不正とは区別する', () {
      final p = domain.pokemon();
      final r = valid(
        DamageRequest.fromDto(
          DamageRequestDto(
            attacker: p,
            defender: p,
            move: MoveDto(
              id: moveId('Counter'),
              type: PokemonType.normal,
              power: 1,
              category: Category.physical,
            ),
            field: domain.field(),
          ),
        ),
      );
      expect(
        (calculateDamage(r) as Failure<DamageResult>).kind,
        FailureKind.unsupported,
      );
    });
  }
}
