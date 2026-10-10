part of 'models.dart';

final class StatStages extends DomainValue {
  const StatStages._(this.atk, this.def, this.spa, this.spd, this.spe);

  final StatStage atk;
  final StatStage def;
  final StatStage spa;
  final StatStage spd;
  final StatStage spe;

  static Validation<StatStages> fromDto(StatStagesDto input) {
    final checks = _Checks();
    return checks.finish(_checkStages(checks, input, 'statStages'));
  }

  StatStagesDto get toDto => StatStagesDto(
    atk: atk.value,
    def: def.value,
    spa: spa.value,
    spd: spd.value,
    spe: spe.value,
  );

  @override
  List<Object?> get _properties => [atk, def, spa, spd, spe];

  /// 能力を指定し、型付きの値を参照する。
  StatStage? operator [](Stat stat) => switch (stat) {
    Stat.atk => atk,
    Stat.def => def,
    Stat.spa => spa,
    Stat.spd => spd,
    Stat.spe => spe,
    Stat.hp => null,
  };
  static final zero = _checked(fromDto(const StatStagesDto()));
}
