import 'package:pokemon_damage_calculator_core/pokemon_damage_calculator_core.dart';

PokemonStateDto pokemon({int hp = 200, AbilityId? ability}) => PokemonStateDto(
  profile: PokemonProfileDto(
    id: PokemonId.pikachu,
    types: [PokemonType.normal],
    weight: 50,
  ),
  stats: StatsDto(hp: 200, atk: 100, def: 100, spa: 100, spd: 100, spe: 100),
  currentHp: hp,
  ability: ability,
);

DamageResult damage(
  MoveId id, {
  int hp = 200,
  int hitIndex = 0,
  AbilityId? ability,
}) {
  final request =
      DamageRequest.fromDto(
            DamageRequestDto(
              attacker: pokemon(),
              defender: pokemon(hp: hp, ability: ability),
              move: MoveDto(
                id: id,
                type: PokemonType.normal,
                power: 20,
                category: Category.physical,
              ),
              field: BattleFieldDto(format: BattleFormat.single),
              hitIndex: hitIndex,
            ),
          )
          as Valid<DamageRequest>;
  return (calculateDamage(request.value) as Success<DamageResult>).value;
}
