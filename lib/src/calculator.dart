import 'combined_engine.dart' as combined;
import 'engine.dart' as engine;
import 'models/dto.dart';
import 'models/models.dart';

/// 検証済みの指定条件とヒット位置からダメージ分布を計算する。
Calculation<DamageResult> calculateDamage(DamageRequest request) =>
    engine.calculateDamage(request);

/// 検証済みの固定分布から、順序付き攻撃列のHP推移と撃破率を計算する。
Calculation<CombinedDamageResult> calculateCombinedDamage(
  CombinedDamageRequest request,
) => combined.calculateCombinedDamage(request);
