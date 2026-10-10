// フィールド
part of '../value_objects.dart';

enum Terrain {
  electric,
  grass,
  misty,
  psychic;

  static Validation<Terrain> create(String id) {
    for (final terrain in values) {
      if (terrain.name == id) return Valid(terrain);
    }
    return Invalid([
      const ValidationError('value', ValidationCode.unknownValue),
    ]);
  }
}
