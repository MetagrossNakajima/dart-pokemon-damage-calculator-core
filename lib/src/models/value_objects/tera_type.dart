// テラスタイプ（通常タイプまたはStellar）
part of '../value_objects.dart';

enum TeraType {
  normal('Normal'),
  fire('Fire'),
  water('Water'),
  electric('Electric'),
  grass('Grass'),
  ice('Ice'),
  fighting('Fighting'),
  poison('Poison'),
  ground('Ground'),
  flying('Flying'),
  psychic('Psychic'),
  bug('Bug'),
  rock('Rock'),
  ghost('Ghost'),
  dragon('Dragon'),
  dark('Dark'),
  steel('Steel'),
  fairy('Fairy'),
  stellar('Stellar');

  const TeraType(this.value);
  final String value;

  factory TeraType.of(PokemonType type) => values[type.index];

  PokemonType? get pokemonType =>
      this == stellar ? null : PokemonType.values[index];

  static Validation<TeraType> create(String id) {
    for (final type in values) {
      if (type.value == id) return Valid(type);
    }
    return Invalid([
      const ValidationError('value', ValidationCode.unknownValue),
    ]);
  }
}
