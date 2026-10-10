part of '../dto.dart';

/// 最初の攻撃前に適用する設置技のDTO。
final class EntryHazardsDto {
  const EntryHazardsDto({this.stealthRock = false, this.spikesLayers = 0});
  final bool stealthRock;
  final int spikesLayers;
}
