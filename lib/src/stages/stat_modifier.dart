import '../battle_effects.dart';
import '../models/dto.dart';
import '../models/models.dart';
import '../models/value_objects.dart';
import 'calculation_context.dart';
import 'common_modifier.dart';

bool isParadoxBoostedStat(
  DamageEffectsContext context,
  PokemonState pokemon,
  AbilityId? ability,
  ItemId? item,
  Stat stat,
) {
  if (!{AbilityId.quarkDrive, AbilityId.protosynthesis}.contains(ability)) {
    return false;
  }
  if (!(item == ItemId.boosterEnergy ||
      pokemonFlag(pokemon, PokemonFlag.boosterEnergy) ||
      (ability == AbilityId.quarkDrive &&
          context.terrain == Terrain.electric) ||
      (ability == AbilityId.protosynthesis &&
          context.weather == Weather.sunlight))) {
    return false;
  }
  var selected = pokemon.boostedStat;
  if (selected == null) {
    // 同値なら攻撃→防御→特攻→特防→素早さの順。厳密な増加時だけ候補を更新する。
    selected = Stat.atk;
    for (final candidate in [Stat.def, Stat.spa, Stat.spd, Stat.spe]) {
      if (rankedStat(
            pokemon.stats[candidate].value,
            pokemon.stages[candidate]?.value ?? 0,
          ) >
          rankedStat(
            pokemon.stats[selected!].value,
            pokemon.stages[selected]?.value ?? 0,
          )) {
        selected = candidate;
      }
    }
  }
  return selected == stat;
}
