import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import '../support/value_objects_fixtures.dart' show valid;

PokemonStateDto pokemon({
  int maxHp = 999,
  int? currentHp,
  AbilityId? ability,
  Status? status,
  int? toxicCounter,
}) => PokemonStateDto(
  profile: PokemonProfileDto(
    id: PokemonId.mew,
    types: [PokemonType.normal],
    weight: 50,
  ),
  stats: StatsDto(hp: maxHp, atk: 100, def: 100, spa: 100, spd: 100, spe: 100),
  currentHp: currentHp,
  ability: ability,
  status: status,
  toxicCounter: toxicCounter,
);

MoveDto move(
  MoveId id, {
  int power = 40,
  PokemonType type = PokemonType.normal,
}) => MoveDto(id: id, type: type, power: power, category: Category.physical);

final field = BattleFieldDto(format: BattleFormat.single);

HitResult hit(PokemonStateDto attacker, MoveDto move) =>
    (calculateDamage(
              valid(
                DamageRequest.fromDto(
                  DamageRequestDto(
                    attacker: attacker,
                    defender: pokemon(),
                    move: move,
                    field: field,
                  ),
                ),
              ),
            )
            as Success<DamageResult>)
        .value
        .hits
        .single;

CombinedDamageRequestDto combinedInput(
  PokemonStateDto defender, {
  BattleSetupDto? setup,
}) => CombinedDamageRequestDto(
  attacks: [
    AttackDto.fromAccuracy(
      turn: 1,
      hits: [
        DamageDistribution({0: BigInt.one}),
      ],
    ),
  ],
  defender: defender,
  field: field,
  setup: setup ?? BattleSetupDto.none,
);

CombinedDamageResult combined(
  PokemonStateDto defender, {
  BattleSetupDto? setup,
}) =>
    (calculateCombinedDamage(
              valid(
                CombinedDamageRequest.fromDto(
                  combinedInput(defender, setup: setup),
                ),
              ),
            )
            as Success<CombinedDamageResult>)
        .value;

void main() {
  test('single-hit requests reject HP above999 before calculation', () {
    for (final value in [1000, 9223372036854775807]) {
      for (final current in [false, true]) {
        final input = current
            ? pokemon(currentHp: value)
            : pokemon(maxHp: value);
        final suffix = current ? 'currentHp' : 'stats.hp';
        for (final attacker in [false, true]) {
          final request = DamageRequest.fromDto(
            DamageRequestDto(
              attacker: attacker ? input : pokemon(),
              defender: attacker ? pokemon() : input,
              move: move(MoveId.pound),
              field: field,
            ),
          );
          final side = attacker ? 'attacker' : 'defender';
          expect(request, isA<Invalid<DamageRequest>>());
          expect((request as Invalid<DamageRequest>).errors, [
            ValidationError(
              'damageRequest.$side.$suffix',
              ValidationCode.outOfRange,
            ),
          ]);
        }
      }
    }
  });

  test('combined requests reject HP above999 before calculation', () {
    for (final value in [1000, 9223372036854775807]) {
      for (final current in [false, true]) {
        final request = CombinedDamageRequest.fromDto(
          combinedInput(
            current ? pokemon(currentHp: value) : pokemon(maxHp: value),
          ),
        );
        final suffix = current ? 'currentHp' : 'stats.hp';
        expect(request, isA<Invalid<CombinedDamageRequest>>());
        expect((request as Invalid<CombinedDamageRequest>).errors, [
          ValidationError(
            'combinedDamageRequest.defender.$suffix',
            ValidationCode.outOfRange,
          ),
        ]);
      }
    }
  });

  test('999 HP keeps full-HP power and ability conditions correct', () {
    for (final id in [
      MoveId.eruption,
      MoveId.waterSpout,
      MoveId.dragonEnergy,
    ]) {
      expect(hit(pokemon(currentHp: 999), move(id, power: 150)).power, 150);
    }
    expect(
      hit(
        pokemon(currentHp: 999, ability: AbilityId.overgrow),
        move(MoveId.pound, type: PokemonType.grass),
      ).attack,
      100,
    );
    expect(
      hit(
        pokemon(currentHp: 999, ability: AbilityId.defeatist),
        move(MoveId.pound),
      ).attack,
      100,
    );
  });

  test('999 HP uses exact low-HP ability thresholds', () {
    for (final hp in [333, 334]) {
      expect(
        hit(
          pokemon(currentHp: hp, ability: AbilityId.overgrow),
          move(MoveId.pound, type: PokemonType.grass),
        ).attack,
        hp == 333 ? 150 : 100,
      );
    }
    for (final hp in [499, 500]) {
      expect(
        hit(
          pokemon(currentHp: hp, ability: AbilityId.defeatist),
          move(MoveId.pound),
        ).attack,
        hp == 499 ? 50 : 100,
      );
    }
  });

  test('999 HP toxic counter15 leaves exactly63 HP', () {
    final result = combined(
      pokemon(currentHp: 999, status: Status.toxic, toxicCounter: 15),
    );
    expect(result.finalHp.weights, {63: BigInt.one});
    expect(result.knockout.weight, BigInt.zero);
  });

  test('999 HP neutral Stealth Rock leaves exactly875 HP', () {
    final result = combined(
      pokemon(currentHp: 999),
      setup: BattleSetupDto(
        entryHazards: const EntryHazardsDto(stealthRock: true),
      ),
    );
    expect(result.finalHp.weights, {875: BigInt.one});
    expect(result.knockout.weight, BigInt.zero);
  });
}
