import 'models/dto.dart';
import 'models/models.dart';
import 'models/value_objects.dart';
import 'rules/ability_rules.dart';

bool pokemonFlag(
  PokemonState pokemon,
  PokemonFlag flag, [
  bool fallback = false,
]) => pokemon.flags[flag] ?? fallback;

AbilityId? activeAbility(
  PokemonState pokemon,
  BattleField field, {
  PokemonState? opponent,
  bool? itemConsumed,
}) {
  final protected =
      pokemon.item == ItemId.abilityShield &&
      !(itemConsumed ?? pokemon.itemConsumed) &&
      !pokemonFlag(pokemon, PokemonFlag.itemSuppressed) &&
      !field.effects.contains(FieldEffect.magicRoom);
  // 有効なとくせいガードによる保護は、個別の抑制や場のガスより優先する。
  if (protected) return pokemon.ability;
  if (pokemonFlag(pokemon, PokemonFlag.abilitySuppressed)) return null;
  if (!ignoresNeutralizingGas(pokemon.ability) &&
      (field.effects.contains(FieldEffect.neutralizingGas) ||
          (opponent?.ability == AbilityId.neutralizingGas &&
              !pokemonFlag(opponent!, PokemonFlag.abilitySuppressed)))) {
    return null;
  }
  return pokemon.ability;
}

ItemId? activeItem(
  PokemonState pokemon,
  BattleField field, {
  PokemonState? opponent,
  bool? itemConsumed,
  bool ignoreConsumption = false,
}) {
  if ((!ignoreConsumption && (itemConsumed ?? pokemon.itemConsumed)) ||
      pokemonFlag(pokemon, PokemonFlag.itemSuppressed) ||
      field.effects.contains(FieldEffect.magicRoom) ||
      activeAbility(
            pokemon,
            field,
            opponent: opponent,
            itemConsumed: itemConsumed,
          ) ==
          AbilityId.klutz) {
    return null;
  }
  return pokemon.item;
}

List<PokemonType> currentTypes(PokemonState pokemon) =>
    pokemon.teraType?.pokemonType != null
    ? [pokemon.teraType!.pokemonType!]
    : pokemon.types;

bool isGrounded(
  PokemonState pokemon,
  BattleField field,
  AbilityId? ability,
  ItemId? item,
) {
  // 強制接地は明示フラグにも優先し、テラスタル後のタイプで通常の接地を決める。
  if (field.gravity || item == ItemId.ironBall) return true;
  final explicit = pokemon.flags[PokemonFlag.grounded];
  if (explicit != null) return explicit;
  return !currentTypes(pokemon).contains(PokemonType.flying) &&
      !{AbilityId.levitate, AbilityId.eelevate}.contains(ability) &&
      item != ItemId.airBalloon;
}

bool weatherSuppressed(Iterable<AbilityId?> abilities) => abilities.any(
  (ability) => ability == AbilityId.cloudNine || ability == AbilityId.airLock,
);

Weather? effectiveWeather(BattleField field, Iterable<AbilityId?> abilities) =>
    weatherSuppressed(abilities) ? null : field.weather;
