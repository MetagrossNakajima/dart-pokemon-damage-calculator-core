import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';

PokemonStateDto defender({
  int hp = 100,
  int? currentHp,
  ItemId? item,
  AbilityId? ability,
  Status? status,
  int? toxicCounter,
  bool itemConsumed = false,
  int? cudChewTurn,
  List<PokemonType> types = const [PokemonType.normal],
  Map<PokemonFlag, bool> flags = const {},
}) => PokemonStateDto(
  profile: PokemonProfileDto(id: PokemonId.pikachu, types: types, weight: 50),
  stats: StatsDto(hp: hp, atk: 100, def: 100, spa: 100, spd: 100, spe: 100),
  currentHp: currentHp,
  item: item,
  ability: ability,
  status: status,
  toxicCounter: toxicCounter,
  itemConsumed: itemConsumed,
  cudChewTurn: cudChewTurn,
  flags: flags,
);

DamageDistribution distribution(Map<int, int> weights) => DamageDistribution({
  for (final e in weights.entries) e.key: BigInt.from(e.value),
});

AttackDto attack(
  List<DamageDistribution> hits, {
  int turn = 1,
  Map<int, int>? counts,
  Map<int, int>? conditional,
}) => AttackDto(
  turn: turn,
  hits: hits,
  hitCounts: {
    for (final e in (counts ?? {hits.length: 1}).entries)
      e.key: BigInt.from(e.value),
  },
  conditionalHitCounts: conditional == null
      ? null
      : {for (final e in conditional.entries) e.key: BigInt.from(e.value)},
);

CombinedDamageRequestDto request(
  List<AttackDto> attacks, {
  PokemonStateDto? pokemon,
  BattleFieldDto? field,
  BattleSetupDto? setup,
  CalculationLimitsDto limits = const CalculationLimitsDto(),
}) => CombinedDamageRequestDto(
  attacks: attacks,
  defender: pokemon ?? defender(),
  field: field ?? BattleFieldDto(format: BattleFormat.single),
  setup: setup ?? BattleSetupDto.none,
  limits: limits,
);

CombinedDamageResult run(CombinedDamageRequestDto dto) {
  final validation = CombinedDamageRequest.fromDto(dto);
  expect(validation, isA<Valid<CombinedDamageRequest>>());
  final calculation = calculateCombinedDamage(
    (validation as Valid<CombinedDamageRequest>).value,
  );
  expect(calculation, isA<Success<CombinedDamageResult>>());
  return (calculation as Success<CombinedDamageResult>).value;
}
