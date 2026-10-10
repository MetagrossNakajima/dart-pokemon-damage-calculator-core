part of '../dto.dart';

/// 未指定を0として扱う、不変の未検証能力ランクDTO。
final class StatStagesDto extends MapBase<Stat, int> {
  const StatStagesDto({
    this.atk = 0,
    this.def = 0,
    this.spa = 0,
    this.spd = 0,
    this.spe = 0,
  });

  /// [values] から能力ランクのDTOを作り、未指定は0として扱う。
  factory StatStagesDto.fromMap(Map<Stat, int> values) => StatStagesDto(
    atk: values[Stat.atk] ?? 0,
    def: values[Stat.def] ?? 0,
    spa: values[Stat.spa] ?? 0,
    spd: values[Stat.spd] ?? 0,
    spe: values[Stat.spe] ?? 0,
  );

  final int atk;
  final int def;
  final int spa;
  final int spd;
  final int spe;

  @override
  Iterable<Stat> get keys => const [
    Stat.atk,
    Stat.def,
    Stat.spa,
    Stat.spd,
    Stat.spe,
  ];

  @override
  int? operator [](Object? key) => switch (key) {
    Stat.atk => atk,
    Stat.def => def,
    Stat.spa => spa,
    Stat.spd => spd,
    Stat.spe => spe,
    _ => null,
  };

  @override
  void operator []=(Stat key, int value) =>
      throw UnsupportedError('StatStagesDto is immutable');

  @override
  void clear() => throw UnsupportedError('StatStagesDto is immutable');

  @override
  int? remove(Object? key) =>
      throw UnsupportedError('StatStagesDto is immutable');
}
