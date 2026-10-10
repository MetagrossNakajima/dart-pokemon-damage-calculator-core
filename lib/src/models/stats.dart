part of 'models.dart';

final class Stats extends DomainValue {
  const Stats._(this.hp, this.atk, this.def, this.spa, this.spd, this.spe);

  final StatValue hp;
  final StatValue atk;
  final StatValue def;
  final StatValue spa;
  final StatValue spd;
  final StatValue spe;

  static Validation<Stats> fromDto(StatsDto input) {
    final checks = _Checks();
    return checks.finish(_checkStats(checks, input, 'stats'));
  }

  StatsDto get toDto => StatsDto(
    hp: hp.value,
    atk: atk.value,
    def: def.value,
    spa: spa.value,
    spd: spd.value,
    spe: spe.value,
  );

  @override
  List<Object?> get _properties => [hp, atk, def, spa, spd, spe];

  /// 能力を指定し、型付きの値を参照する。
  StatValue operator [](Stat stat) => switch (stat) {
    Stat.hp => hp,
    Stat.atk => atk,
    Stat.def => def,
    Stat.spa => spa,
    Stat.spd => spd,
    Stat.spe => spe,
  };
}
