part of '../dto.dart';

/// トレースを生成した計算段階。
///
/// 複数の段階に登場するルールも、段階を型で区別できる。
enum ModifierStage {
  basePower,
  power,
  powerModifier,
  attack,
  attackModifier,
  defense,
  defenseModifier,
  damage,
  damageModifier,
}
