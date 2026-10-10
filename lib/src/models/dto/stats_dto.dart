part of '../dto.dart';

/// 6能力の実数値を持つ、不変の未検証入力DTO。
final class StatsDto extends MapBase<Stat, int> {
  const StatsDto({
    required this.hp,
    required this.atk,
    required this.def,
    required this.spa,
    required this.spd,
    required this.spe,
  });

  /// マップから実数値のDTOを作り、未指定の能力は検証で拒否できる0とする。
  factory StatsDto.fromMap(Map<Stat, int> values) => StatsDto(
    hp: values[Stat.hp] ?? 0,
    atk: values[Stat.atk] ?? 0,
    def: values[Stat.def] ?? 0,
    spa: values[Stat.spa] ?? 0,
    spd: values[Stat.spd] ?? 0,
    spe: values[Stat.spe] ?? 0,
  );

  final int hp;
  final int atk;
  final int def;
  final int spa;
  final int spd;
  final int spe;

  @override
  Iterable<Stat> get keys => Stat.values;

  @override
  int? operator [](Object? key) => switch (key) {
    Stat.hp => hp,
    Stat.atk => atk,
    Stat.def => def,
    Stat.spa => spa,
    Stat.spd => spd,
    Stat.spe => spe,
    _ => null,
  };

  @override
  void operator []=(Stat key, int value) =>
      throw UnsupportedError('StatsDto is immutable');

  @override
  void clear() => throw UnsupportedError('StatsDto is immutable');

  @override
  int? remove(Object? key) => throw UnsupportedError('StatsDto is immutable');
}
