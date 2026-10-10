import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import 'package:test/test.dart';
import '../../support/effects_fixtures.dart' as effects;
import '../../support/calculator_fixtures.dart' as calculator;
import '../../support/effect_regressions_fixtures.dart' as regressions;
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

void main() {
  group('ハイドロスチームの天候補正', () {
    // Smogon cf95cb685b6cbbda1ea5f9dc783f62e3c3e3e900 / Gen 9。
    // Lv50、HP200、その他の実数値100、両者ノーマルタイプで16乱数を取得。
    const boosted = [
      46,
      47,
      47,
      48,
      48,
      49,
      50,
      50,
      51,
      51,
      52,
      52,
      53,
      53,
      54,
      55,
    ];
    const ordinary = [
      31,
      31,
      32,
      32,
      32,
      33,
      33,
      34,
      34,
      34,
      35,
      35,
      35,
      36,
      36,
      37,
    ];
    const halved = [
      15,
      15,
      15,
      15,
      16,
      16,
      16,
      16,
      16,
      16,
      17,
      17,
      17,
      17,
      17,
      18,
    ];
    const normalized = [
      84,
      84,
      85,
      87,
      87,
      88,
      90,
      90,
      91,
      93,
      93,
      94,
      96,
      96,
      97,
      99,
    ];
    final move = effects.m(
      id: 'HydroSteam',
      type: 'Water',
      power: 80,
      category: Category.special,
    );
    final cases =
        <(String, Weather?, String?, String?, String?, String?, List<int>)>[
          ('晴れで1.5倍になる', Weather.sunlight, null, null, null, null, boosted),
          (
            '防御側の傘より晴れ補正を優先する',
            Weather.sunlight,
            null,
            null,
            null,
            'UtilityUmbrella',
            boosted,
          ),
          (
            '攻撃側の傘があると晴れで半減する',
            Weather.sunlight,
            null,
            'UtilityUmbrella',
            null,
            null,
            halved,
          ),
          (
            '両者の傘があると晴れでも通常ダメージになる',
            Weather.sunlight,
            null,
            'UtilityUmbrella',
            null,
            'UtilityUmbrella',
            ordinary,
          ),
          ('雨で1.5倍になる', Weather.rain, null, null, null, null, boosted),
          (
            '防御側の傘があると雨でも通常ダメージになる',
            Weather.rain,
            null,
            null,
            null,
            'UtilityUmbrella',
            ordinary,
          ),
          (
            '攻撃側の傘だけでは雨補正を防がない',
            Weather.rain,
            null,
            'UtilityUmbrella',
            null,
            null,
            boosted,
          ),
          ('天候なしでは通常ダメージになる', null, null, null, null, null, ordinary),
          ('砂では通常ダメージになる', Weather.sandstorm, null, null, null, null, ordinary),
          ('雪では通常ダメージになる', Weather.snow, null, null, null, null, ordinary),
          (
            'ノーてんきで晴れ補正を失う',
            Weather.sunlight,
            null,
            null,
            'CloudNine',
            null,
            ordinary,
          ),
          (
            'エアロックで晴れ補正を失う',
            Weather.sunlight,
            'AirLock',
            null,
            null,
            null,
            ordinary,
          ),
          ('MegaSolで天候なしでも1.5倍になる', null, 'MegaSol', null, null, null, boosted),
          (
            'MegaSolで雨でも1.5倍になる',
            Weather.rain,
            'MegaSol',
            null,
            null,
            null,
            boosted,
          ),
          (
            'MegaSolでも防御側の傘より補正を優先する',
            null,
            'MegaSol',
            null,
            null,
            'UtilityUmbrella',
            boosted,
          ),
          (
            'MegaSolでも攻撃側の傘があると半減する',
            null,
            'MegaSol',
            'UtilityUmbrella',
            null,
            null,
            halved,
          ),
          (
            'MegaSolの補正はノーてんきでも残る',
            Weather.sunlight,
            'MegaSol',
            null,
            'CloudNine',
            null,
            boosted,
          ),
          (
            'ノーマルスキンでも晴れ補正を適用する',
            Weather.sunlight,
            'Normalize',
            null,
            null,
            null,
            normalized,
          ),
        ];
    for (final (
          name,
          weather,
          attackerAbility,
          attackerItem,
          defenderAbility,
          defenderItem,
          rolls,
        )
        in cases) {
      test('ハイドロスチームは$name', () {
        regressions.expectRolls(
          calculator.damage(
            a: effects.p(ability: attackerAbility, item: attackerItem),
            d: effects.p(ability: defenderAbility, item: defenderItem),
            m: move,
            f: effects.f(weather: weather),
          ),
          rolls,
        );
      });
    }

    test('マジックルームは攻撃側の傘を無効化して晴れ補正を戻す', () {
      regressions.expectRolls(
        calculator.damage(
          a: effects.p(item: 'UtilityUmbrella'),
          m: move,
          f: effects.f(
            weather: Weather.sunlight,
            effects: {FieldEffect.magicRoom},
          ),
        ),
        boosted,
      );
    });

    test('通常の水技は晴れで半減する', () {
      regressions.expectRolls(
        calculator.damage(
          m: effects.m(
            id: 'Scald',
            type: 'Water',
            power: 80,
            category: Category.special,
          ),
          f: effects.f(weather: Weather.sunlight),
        ),
        halved,
      );
    });
  });
  {
    test('Utility Umbrella blocks defender-side rain damage amplification', () {
      final move = effects.m(type: 'Water');
      final rain = effects.f(weather: Weather.rain);
      final ordinary = effects.hit(move: move, field: rain);
      final protected = effects.hit(
        d: effects.p(item: 'UtilityUmbrella'),
        move: move,
        field: rain,
      );

      expect(ordinary.rolls.last, 28);
      expect(protected.rolls.last, 19);
      expect(ordinary.trace.any((entry) => entry.id == 'Weather'), true);
      expect(protected.trace.any((entry) => entry.id == 'Weather'), false);
    });
  }
  {
    test('tera STAB retains original typing and strengthens matching tera', () {
      final normal = effects.hit(a: effects.p(tera: 'Normal'));
      expect(normal.power, 60);
      expect(normal.rolls.last, 56); // base28 *2
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Normal', ability: 'Adaptability'),
            )
            .rolls
            .last,
        63,
      );
      final newType = effects.hit(
        a: effects.p(tera: 'Fire'),
        move: effects.m(type: 'Fire', power: 80),
      );
      expect(newType.rolls.last, 55); // base37 *1.5 ->55
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Fire', ability: 'Adaptability'),
              move: effects.m(type: 'Fire', power: 80),
            )
            .rolls
            .last,
        74,
      );
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Fire', ability: 'Adaptability'),
            )
            .rolls
            .last,
        28,
      ); // former type retains ordinary STAB
      expect(
        effects
            .hit(
              d: effects.p(types: ['Ghost'], tera: 'Normal'),
            )
            .rolls
            .last,
        28,
      );
      expect(effects.hit(d: effects.p(tera: 'Ghost')).rolls.last, 0);
    });

    test('Stellar boost state and type effectiveness', () {
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Stellar'),
              move: effects.m(power: 80),
            )
            .rolls
            .last,
        74,
      );
      expect(
        effects
            .hit(
              a: effects.p(
                tera: 'Stellar',
                flags: {PokemonFlag.stellarBoostAvailable: false},
              ),
              move: effects.m(power: 80),
            )
            .rolls
            .last,
        55,
      );
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Stellar'),
              move: effects.m(type: 'Fire', power: 80),
            )
            .rolls
            .last,
        44,
      );
      final teraBlast = effects.m(
        id: 'TeraBlast',
        power: 80,
        category: Category.special,
      );
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Stellar'),
              move: teraBlast,
            )
            .power,
        100,
      );
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Stellar'),
              move: teraBlast,
            )
            .rolls
            .last,
        55,
      );
      expect(
        effects
            .hit(
              a: effects.p(tera: 'Stellar'),
              d: effects.p(tera: 'Water'),
              move: teraBlast,
            )
            .rolls
            .last,
        110,
      );
      expect(
        effects
            .hit(
              a: effects.p(
                id: 'Terapagos-Stellar',
                tera: 'Stellar',
                flags: {PokemonFlag.stellarBoostAvailable: false},
              ),
              move: effects.m(power: 80),
            )
            .rolls
            .last,
        74,
      );
    });
  }
}
