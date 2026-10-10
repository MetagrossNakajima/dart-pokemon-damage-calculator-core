part of '../dto.dart';

/// 指定条件の1ヒットの、正確なダメージ計算結果。
final class DamageResult {
  DamageResult(this.distribution, this.referenceHp, List<HitResult> hits)
    : hits = List.unmodifiable(hits);
  final DamageDistribution distribution;
  final int referenceHp;

  /// 算出した1ヒットの乱数と補正情報。
  final List<HitResult> hits;
  int get min => distribution.min;
  int get max => distribution.max;
  double get minPercent => min * 100 / referenceHp;
  double get maxPercent => max * 100 / referenceHp;
}
