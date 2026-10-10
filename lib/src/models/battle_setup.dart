part of 'models.dart';

final class BattleSetup extends DomainValue {
  const BattleSetup._(this.entryHazards, this.initialDamages);

  final EntryHazards entryHazards;
  final List<int> initialDamages;

  static Validation<BattleSetup> fromDto(BattleSetupDto input) {
    final checks = _Checks();
    return checks.finish(_checkSetup(checks, input, 'battleSetup'));
  }

  BattleSetupDto get toDto => BattleSetupDto(
    entryHazards: entryHazards.toDto,
    initialDamages: initialDamages,
  );

  @override
  List<Object?> get _properties => [entryHazards, initialDamages];
  static final none = _checked(fromDto(BattleSetupDto.none));
}
