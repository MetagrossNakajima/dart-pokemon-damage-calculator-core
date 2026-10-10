// 通常タイプ（Stellarを除く）
part of '../value_objects.dart';

enum PokemonType {
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
  fairy('Fairy');

  const PokemonType(this.id);
  final String id;
  static Validation<PokemonType> create(String id) {
    for (final type in values) {
      if (type.id == id) return Valid(type);
    }
    return Invalid([
      const ValidationError('value', ValidationCode.unknownValue),
    ]);
  }
}
