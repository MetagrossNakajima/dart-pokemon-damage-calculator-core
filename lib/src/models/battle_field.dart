part of 'models.dart';

final class BattleField extends DomainValue {
  BattleField._fromDto(BattleFieldDto input)
    : format = input.format,
      weather = input.weather,
      gravity = input.gravity,
      terrain = input.terrain,
      effects = Set.unmodifiable(input.effects);

  final BattleFormat format;
  final Weather? weather;
  final bool gravity;
  final Terrain? terrain;
  final Set<FieldEffect> effects;

  static Validation<BattleField> fromDto(BattleFieldDto input) =>
      Valid(BattleField._fromDto(input));

  BattleFieldDto get toDto => BattleFieldDto(
    format: format,
    weather: weather,
    gravity: gravity,
    terrain: terrain,
    effects: effects,
  );

  @override
  List<Object?> get _properties => [format, weather, gravity, terrain, effects];
}
