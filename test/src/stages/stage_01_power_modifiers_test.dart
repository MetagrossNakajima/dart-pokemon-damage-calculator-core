import '../../support/input_adapter.dart'
    hide
        Calculation,
        Success,
        Failure,
        FailureKind,
        calculateDamage,
        calculateCombinedDamage;
import '../../support/pokemon_patch.dart';
import 'package:test/test.dart';
import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import '../../support/effects_fixtures.dart' as effects;

void main() {
  final powerCases =
      <
        ({
          String ability,
          MoveDto move,
          PokemonStateDto? defender,
          BattleFieldDto? field,
          Status? status,
          Map<PokemonFlag, bool> flags,
          int fainted,
          Gender gender,
          int expected,
        })
      >[
        (
          ability: 'IronFist',
          move: effects.m(flags: {MoveFlag.punch}),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 48,
        ),
        (
          ability: 'Reckless',
          move: effects.m(flags: {MoveFlag.recoil}),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 48,
        ),
        (
          ability: 'SheerForce',
          move: effects.m(flags: {MoveFlag.sheerForce}),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 52,
        ),
        (
          ability: 'SandForce',
          move: effects.m(type: 'Rock'),
          defender: null,
          field: effects.f(weather: Weather.sandstorm),
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 52,
        ),
        (
          ability: 'Analytic',
          move: effects.m(),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 52,
        ),
        (
          ability: 'ToughClaws',
          move: effects.m(flags: {MoveFlag.contact}),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 52,
        ),
        (
          ability: 'PunkRock',
          move: effects.m(flags: {MoveFlag.sound}),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 52,
        ),
        (
          ability: 'Sharpness',
          move: effects.m(flags: {MoveFlag.sharpness}),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 60,
        ),
        (
          ability: 'Technician',
          move: effects.m(),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 60,
        ),
        (
          ability: 'FlareBoost',
          move: effects.m(category: Category.special),
          defender: null,
          field: null,
          status: Status.burn,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 60,
        ),
        (
          ability: 'ToxicBoost',
          move: effects.m(),
          defender: null,
          field: null,
          status: Status.poison,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 60,
        ),
        (
          ability: 'StrongJaw',
          move: effects.m(flags: {MoveFlag.bite}),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 60,
        ),
        (
          ability: 'MegaLauncher',
          move: effects.m(flags: {MoveFlag.pulse}),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 60,
        ),
        (
          ability: 'SteelySpirit',
          move: effects.m(type: 'Steel'),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 60,
        ),
        (
          ability: 'FairyAura',
          move: effects.m(type: 'Fairy'),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 53,
        ),
        (
          ability: 'DarkAura',
          move: effects.m(type: 'Dark'),
          defender: effects.p(ability: 'AuraBreak'),
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.genderless,
          expected: 30,
        ),
        (
          ability: 'Rivalry',
          move: effects.m(),
          defender: effects.p(gender: Gender.male),
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.male,
          expected: 50,
        ),
        (
          ability: 'Rivalry',
          move: effects.m(),
          defender: effects.p(gender: Gender.female),
          field: null,
          status: null,
          flags: {},
          fainted: 0,
          gender: Gender.male,
          expected: 30,
        ),
        (
          ability: 'SupremeOverlord',
          move: effects.m(),
          defender: null,
          field: null,
          status: null,
          flags: {},
          fainted: 5,
          gender: Gender.genderless,
          expected: 60,
        ),
      ];

  for (final c in powerCases) {
    test('power ${c.ability} ${c.expected}', () {
      final a = effects.p(
        ability: c.ability,
        status: c.status,
        flags: c.flags,
        fainted: c.fainted,
        gender: c.gender,
      );
      expect(
        effects.hit(a: a, d: c.defender, move: c.move, field: c.field).power,
        c.expected,
      );
      expect(
        effects
            .hit(
              a: effects.change(
                a,
                PokemonPatch(ability: const Replacement(null)),
              ),
              d: c.defender,
              move: c.move,
              field: c.field,
            )
            .power,
        40,
      );
    });
  }

  test('normalize and liquid voice do not share a power boost', () {
    expect(
      effects
          .hit(
            a: effects.p(ability: 'Normalize'),
            move: effects.m(type: 'Fire'),
          )
          .power,
      48,
    );
    expect(
      effects
          .hit(
            a: effects.p(ability: 'LiquidVoice'),
            move: effects.m(flags: {MoveFlag.sound}),
            d: effects.p(types: ['Fire']),
          )
          .rolls
          .last,
      38,
    );
    expect(effects.hit(a: effects.p(ability: 'LiquidVoice')).power, 40);
  });

  for (final entry in {
    'MuscleBand': 44,
    'WiseGlasses': 44,
    'PunchingGlove': 44,
    'NormalGem': 52,
    'TypePlate': 40,
    'SilkScarf': 48,
  }.entries) {
    test('power item ${entry.key}', () {
      final move = effects.m(
        category: entry.key == 'WiseGlasses'
            ? Category.special
            : Category.physical,
        flags: {MoveFlag.punch},
      );
      expect(
        effects
            .hit(
              a: effects.p(item: entry.key),
              move: move,
            )
            .power,
        entry.value,
      );
    });
  }

  for (final c in [
    ('Dialga', 'AdamantOrb', 'Steel'),
    ('Dialga-Origin', 'AdamantCrystal', 'Dragon'),
    ('Palkia', 'LustrousOrb', 'Water'),
    ('Palkia-Origin', 'LustrousGlobe', 'Dragon'),
    ('Giratina', 'GriseousOrb', 'Ghost'),
    ('Giratina-Origin', 'GriseousCore', 'Dragon'),
    ('Latios', 'SoulDew', 'Psychic'),
    ('Latias', 'SoulDew', 'Dragon'),
  ]) {
    test('species orb $c', () {
      expect(
        effects
            .hit(
              a: effects.p(id: c.$1, item: c.$2),
              move: effects.m(type: c.$3),
            )
            .power,
        48,
      );
      expect(
        effects
            .hit(
              a: effects.p(id: 'Other', item: c.$2),
              move: effects.m(type: c.$3),
            )
            .power,
        40,
      );
      expect(
        effects
            .hit(
              a: effects.p(id: c.$1, item: c.$2),
              move: effects.m(),
            )
            .power,
        40,
      );
    });
  }

  for (final c in [
    (Terrain.electric, 'Electric'),
    (Terrain.grass, 'Grass'),
    (Terrain.psychic, 'Psychic'),
  ]) {
    test('terrain grounding ${c.$1}', () {
      final field = effects.f(terrain: c.$1);
      expect(
        effects
            .hit(
              move: effects.m(type: c.$2),
              field: field,
            )
            .power,
        52,
      );
      expect(
        effects
            .hit(
              a: effects.p(types: ['Flying']),
              move: effects.m(type: c.$2),
              field: field,
            )
            .power,
        40,
      );
      expect(
        effects
            .hit(
              a: effects.p(ability: 'Levitate'),
              move: effects.m(type: c.$2),
              field: field,
            )
            .power,
        40,
      );
      expect(
        effects
            .hit(
              a: effects.p(item: 'AirBalloon'),
              move: effects.m(type: c.$2),
              field: field,
            )
            .power,
        40,
      );
      expect(
        effects
            .hit(
              a: effects.p(types: ['Flying'], item: 'IronBall'),
              move: effects.m(type: c.$2),
              field: field,
            )
            .power,
        52,
      );
      expect(
        effects
            .hit(
              a: effects.p(flags: {PokemonFlag.grounded: false}),
              move: effects.m(type: c.$2),
              field: field,
            )
            .power,
        40,
      );
      expect(
        effects
            .hit(
              a: effects.p(types: ['Flying']),
              move: effects.m(type: c.$2),
              field: effects.f(terrain: c.$1, gravity: true),
            )
            .power,
        52,
      );
    });
  }

  test('terrain move-specific conditions', () {
    expect(
      effects
          .hit(
            move: effects.m(id: 'Psyblade'),
            field: effects.f(terrain: Terrain.electric),
          )
          .power,
      60,
    );
    expect(
      effects
          .hit(
            move: effects.m(id: 'ExpandingForce', type: 'Psychic'),
            field: effects.f(terrain: Terrain.psychic),
          )
          .power,
      78,
    );
    expect(
      effects
          .hit(
            move: effects.m(id: 'RisingVoltage', type: 'Electric'),
            field: effects.f(terrain: Terrain.electric),
          )
          .power,
      104,
    );
    expect(
      effects
          .hit(
            move: effects.m(id: 'RisingVoltage', type: 'Electric'),
            d: effects.p(types: ['Flying']),
            field: effects.f(terrain: Terrain.electric),
          )
          .power,
      52,
    );
    expect(
      effects
          .hit(
            move: effects.m(type: 'Dragon'),
            field: effects.f(terrain: Terrain.misty),
          )
          .power,
      20,
    );
    expect(
      effects
          .hit(
            move: effects.m(id: 'Earthquake', type: 'Ground'),
            field: effects.f(terrain: Terrain.grass),
          )
          .power,
      20,
    );
    expect(
      effects
          .hit(
            move: effects.m(id: 'Earthquake', type: 'Ground'),
            d: effects.p(types: ['Flying']),
            field: effects.f(terrain: Terrain.grass),
          )
          .power,
      40,
    );
  });

  for (final c in [
    (FieldEffect.helpingHand, 60),
    (FieldEffect.powerSpot, 52),
    (FieldEffect.battery, 52),
  ]) {
    test('ally ${c.$1}', () {
      final move = effects.m(type: 'Normal', category: Category.special);
      expect(
        effects
            .hit(
              move: move,
              field: effects.f(effects: {c.$1}),
            )
            .power,
        c.$2,
      );
    });
  }
}
