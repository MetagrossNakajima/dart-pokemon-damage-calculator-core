import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';

PokemonStateDto pokemon({
  AbilityId? ability,
  ItemId? item,
  bool itemConsumed = false,
  List<PokemonType> types = const [PokemonType.normal],
  TeraType? tera,
  Map<PokemonFlag, bool> flags = const {},
}) => PokemonStateDto(
  profile: PokemonProfileDto(id: PokemonId.pikachu, types: types, weight: 50),
  stats: const StatsDto(
    hp: 200,
    atk: 100,
    def: 100,
    spa: 100,
    spd: 100,
    spe: 100,
  ),
  ability: ability,
  item: item,
  itemConsumed: itemConsumed,
  teraType: tera,
  flags: flags,
);

BattleFieldDto defaultField({
  bool gravity = false,
  Weather? weather,
  Set<FieldEffect> effects = const {},
}) => BattleFieldDto(
  format: BattleFormat.single,
  gravity: gravity,
  weather: weather,
  effects: effects,
);

DamageResult damage({
  PokemonStateDto? attacker,
  required PokemonStateDto defender,
  PokemonType type = PokemonType.ground,
  MoveId id = MoveId.tackle,
  BattleFieldDto? field,
}) {
  final validation = DamageRequest.fromDto(
    DamageRequestDto(
      attacker: attacker ?? pokemon(),
      defender: defender,
      move: MoveDto(id: id, type: type, power: 40, category: Category.physical),
      field: field ?? defaultField(),
    ),
  );
  expect(validation, isA<Valid<DamageRequest>>());
  final calculation = calculateDamage(
    (validation as Valid<DamageRequest>).value,
  );
  expect(calculation, isA<Success<DamageResult>>());
  return (calculation as Success<DamageResult>).value;
}

CombinedDamageResult combine({
  required PokemonStateDto defender,
  BattleFieldDto? field,
  EntryHazardsDto hazards = const EntryHazardsDto(),
  List<int> initialDamages = const [],
}) {
  final validation = CombinedDamageRequest.fromDto(
    CombinedDamageRequestDto(
      defender: defender,
      field: field ?? defaultField(),
      setup: BattleSetupDto(
        entryHazards: hazards,
        initialDamages: initialDamages,
      ),
      attacks: [
        AttackDto(
          turn: 1,
          hits: [
            DamageDistribution({0: BigInt.one}),
          ],
          hitCounts: {1: BigInt.one},
        ),
      ],
    ),
  );
  expect(validation, isA<Valid<CombinedDamageRequest>>());
  final calculation = calculateCombinedDamage(
    (validation as Valid<CombinedDamageRequest>).value,
  );
  expect(calculation, isA<Success<CombinedDamageResult>>());
  return (calculation as Success<CombinedDamageResult>).value;
}

const neutralRolls = [
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
  18,
  18,
  18,
  18,
  19,
];

const ripenRolls = [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9];

const stellarSuperEffectiveRolls = [
  78,
  78,
  80,
  80,
  80,
  82,
  82,
  84,
  84,
  86,
  86,
  88,
  88,
  90,
  90,
  92,
];

void expectRolls(DamageResult result, List<int> rolls) {
  expect(result.hits.single.rolls, rolls);
  expect(result.distribution.weights, {
    for (final damage in rolls.toSet())
      damage: BigInt.from(rolls.where((roll) => roll == damage).length),
  });
  expect(result.distribution.totalWeight, BigInt.from(16));
}

void expectHp(
  CombinedDamageResult result,
  int hp, {
  bool itemConsumed = false,
}) {
  expect(result.finalHp.weights, {hp: BigInt.one});
  expect(result.attackDamage.weights, {BigInt.from(0): BigInt.one});
  expect(result.knockout.weight, hp == 0 ? BigInt.one : BigInt.zero);
  expect(result.knockout.totalWeight, BigInt.one);
  expect(result.finalStates, hasLength(1));
  expect(result.finalStates.single.weight, BigInt.one);
  expect(result.finalStates.single.state.currentHp, hp);
  expect(result.finalStates.single.state.itemConsumed, itemConsumed);
}
