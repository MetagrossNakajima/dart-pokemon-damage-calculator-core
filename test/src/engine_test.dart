import 'dart:convert';
import 'dart:io';
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
import '../support/effects_fixtures.dart' as effects;
import '../support/fixed_hit_damage_fixtures.dart' as fixed_hit;

void main() {
  {
    final fixtures =
        jsonDecode(File('test/fixtures/web.json').readAsStringSync()) as List;

    for (final fixture in fixtures.cast<Map>()) {
      test('Web pipeline: ${fixture['name']}', () {
        final r = calculator.damage(
          a: calculator.pokemon(
            types: [fixture['type'] as String],
            item: fixture['item'] as String?,
            status: fixture['status'] == null
                ? null
                : Status.values.byName(fixture['status'] as String),
          ),
          d: calculator.pokemon(
            types: [fixture['defenderType'] as String? ?? 'Normal'],
            item: fixture['defenderItem'] as String?,
          ),
          m: calculator.move(
            type: fixture['type'] as String,
            power: fixture['power'] as int,
            category: Category.values.byName(fixture['category'] as String),
            spread: fixture['spread'] == true,
          ),
          f: BattleFieldDto(
            format: fixture['format'] == 'double'
                ? BattleFormat.double
                : BattleFormat.single,
            weather: fixture['weather'] == null
                ? null
                : Weather.values.byName(fixture['weather'] as String),
          ),
        );
        expect(r.hits.single.rolls, fixture['expected']);
      });
    }

    test('state transitions do not cap a move distribution at current HP', () {
      final withoutTransitions = calculator.damage(
        d: calculator.pokemon(hp: 2, fullHp: false),
      );
      final withTransitions = calculator.damage(
        d: calculator.pokemon(hp: 2, fullHp: false, item: 'Leftovers'),
      );
      expect(
        withTransitions.distribution.weights,
        withoutTransitions.distribution.weights,
      );
      expect(withTransitions.min, 24);
      expect(withTransitions.max, 28);
    });
  }
  {
    test(
      'unknown move ability and item use the supplied normal damage data',
      () {
        final actual = effects.hit(
          a: effects.p(
            ability: 'FutureAbility',
            item: 'FutureItem',
            stats: {Stat.atk: 200},
          ),
          d: effects.p(
            ability: 'FutureDefenderAbility',
            item: 'FutureDefenderItem',
          ),
          move: effects.m(
            id: 'FutureMove',
            type: 'Fire',
            power: 90,
            category: Category.special,
          ),
        );
        final expected = effects.hit(
          move: effects.m(type: 'Fire', power: 90, category: Category.special),
        );
        expect(actual.power, 90);
        expect(actual.attack, 100);
        expect(actual.defense, 100);
        expect(actual.rolls, [
          34,
          35,
          35,
          36,
          36,
          36,
          37,
          37,
          38,
          38,
          38,
          39,
          39,
          40,
          40,
          41,
        ]);
        expect(actual.rolls, expected.rolls);
        expect(actual.attack, expected.attack);
        expect(actual.defense, expected.defense);
      },
    );
  }
  {
    final cases =
        jsonDecode(File('test/fixtures/spec_audit.json').readAsStringSync())
            as List<dynamic>;

    for (final value in cases) {
      final c = value as Map<String, dynamic>;
      // HP依存3技は、同じ補正条件の満タン時Smogon参照を用いる。
      final fixedFullHp = {
        'CrushGrip',
        'WringOut',
        'HardPress',
      }.contains(c['name']);
      final reference = fixedFullHp
          ? cases.cast<Map<String, dynamic>>().firstWhere(
              (candidate) =>
                  candidate['name'] == c['name'] &&
                  candidate['hp'] == 200 &&
                  candidate['ability'] == c['ability'] &&
                  candidate['item'] == c['item'],
            )
          : c;
      test('pinned smogon specification ${c['id']}', () {
        final result = adapter.calculateDamage(
          DamageRequestDto(
            attacker: effects.p(
              ability: c['ability'] as String?,
              item: c['item'] as String?,
            ),
            defender: effects.p(hp: c['hp'] as int),
            move: effects.m(
              id: c['name'] as String,
              type: c['type'] as String,
              power: c['name'] == 'WeatherBall' ? 50 : 1,
              category: c['category'] == 'special'
                  ? Category.special
                  : Category.physical,
            ),
            field: effects.f(
              weather: switch (c['weather']) {
                'Sun' => Weather.sunlight,
                'Rain' => Weather.rain,
                'Sand' => Weather.sandstorm,
                'Snow' => Weather.snow,
                _ => null,
              },
            ),
          ),
        );
        final hit = (result as adapter.Success<DamageResult>).value.hits.first;
        // 威力補正後の値と16乱数全体を固定し、丸めによる同ダメージも区別する。
        // 参照元の表示威力はテクニシャン補正前。補正の結果は16乱数で確認する。
        if (c['ability'] != 'Technician') expect(hit.power, reference['power']);
        expect(hit.rolls, reference['rolls']);
      });
    }
  }
  {
    test(
      'Triple Axel calculates each specified hit with sixteen independent rolls',
      () {
        for (var position = 0; position < 3; position++) {
          final result = fixed_hit.damage(
            MoveId.tripleAxel,
            hitIndex: position,
          );
          expect(result.hits, hasLength(1));
          expect(result.hits.single.power, 20 * (position + 1));
          expect(result.hits.single.rolls, hasLength(16));
          expect(result.distribution.totalWeight, BigInt.from(16));
        }
      },
    );
  }
  {
    test('Merciless still respects critical prevention', () {
      expect(
        effects
            .hit(
              a: effects.p(ability: 'Merciless'),
              d: effects.p(status: Status.poison),
            )
            .critical,
        true,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'Merciless'),
              d: effects.p(status: Status.toxic, ability: 'BattleArmor'),
            )
            .critical,
        false,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'Merciless'),
              d: effects.p(status: Status.burn),
            )
            .critical,
        false,
      );
    });
  }
}
