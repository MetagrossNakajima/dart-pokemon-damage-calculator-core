part of '../dto.dart';

/// 明示的な一時状態。未指定のフラグには通常の対戦時の既定値を使う。
enum PokemonFlag {
  grounded,
  abilitySuppressed,
  itemSuppressed,
  flashFire,
  slowStart,
  switchedIn,
  damagedThisTurn,
  movesFirst,
  charge,
  canEvolve,
  transformed,
  itemRemovable,
  boosterEnergy,
  plusMinusAlly,
  stellarBoostAvailable,
}
