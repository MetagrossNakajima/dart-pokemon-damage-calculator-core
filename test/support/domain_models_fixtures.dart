import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';
import 'package:test/test.dart';
import 'input_adapter.dart' show pokemonId, moveId, abilityId, itemId;

const stats = StatsDto(
  hp: 200,
  atk: 100,
  def: 100,
  spa: 100,
  spd: 100,
  spe: 100,
);

PokemonStateDto pokemon({bool detailed = false}) => PokemonStateDto(
  profile: PokemonProfileDto(
    id: pokemonId('test'),
    types: [PokemonType.normal, PokemonType.water],
    weight: 50,
  ),
  stats: stats,
  stages: const StatStagesDto(atk: 1, def: -1, spa: 2, spd: -2, spe: 3),
  ability: abilityId(detailed ? 'SkillLink' : null),
  item: itemId(detailed ? 'UtilityUmbrella' : null),
  status: detailed ? Status.toxic : null,
  currentHp: detailed ? 100 : null,
  toxicCounter: detailed ? 2 : null,
  cudChewTurn: detailed ? -1 : null,
  teraType: detailed ? TeraType.stellar : null,
  boostedStat: detailed ? Stat.spa : null,
  faintedAllies: 2,
  timesHit: 3,
  sideConditions: SideConditions(reflect: detailed, lightScreen: detailed),
  flags: {PokemonFlag.grounded: true, PokemonFlag.flashFire: false},
);

MoveDto move() => MoveDto(
  id: moveId('BulletSeed'),
  type: PokemonType.grass,
  power: 25,
  category: Category.physical,
  flags: {MoveFlag.contact, MoveFlag.bullet},
);

BattleFieldDto field({bool detailed = false}) => BattleFieldDto(
  format: BattleFormat.single,
  terrain: detailed ? Terrain.grass : null,
  effects: {FieldEffect.friendGuard, FieldEffect.battery},
);

void equality<T extends DomainValue>(T a, T b) {
  expect(a, b);
  expect(a.hashCode, b.hashCode);
  expect(a == Object(), isFalse);
  // DTOへの変換後も元のプリミティブを保持することを確認する。
  expect((a as dynamic).toDto, isNotNull);
}
