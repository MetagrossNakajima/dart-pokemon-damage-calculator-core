part of 'models.dart';

final class Move extends DomainValue {
  const Move._({
    required this.id,
    required this.type,
    required this.power,
    required this.category,
    required this.spread,
    required this.flags,
    required this.priority,
  });

  final MoveId id;
  final PokemonType type;
  final MovePower power;
  final Category category;
  final bool spread;
  final Set<MoveFlag> flags;
  final MovePriority priority;

  static Validation<Move> fromDto(MoveDto input) {
    final checks = _Checks();
    return checks.finish(_checkMove(checks, input, 'move'));
  }

  MoveDto get toDto => MoveDto(
    id: id,
    type: type,
    power: power.value,
    category: category,
    spread: spread,
    flags: flags,
    priority: priority.value,
  );

  @override
  List<Object?> get _properties => [
    id,
    type,
    power,
    category,
    spread,
    flags,
    priority,
  ];
}
