/// 検証済みの不変モデルから、Pure Dartで正確なダメージ分布を計算する。
///
/// `fromDto` の結果が [Valid] なら計算APIへ渡し、[Invalid] なら入力エラーを扱う。
/// 未対応の仕様と計算量制限による失敗は、計算結果として返す。
library;

export 'src/models/dto.dart';
export 'src/models/models.dart';
export 'src/models/validation.dart';
export 'src/models/value_objects.dart';
export 'src/calculator.dart' show calculateDamage, calculateCombinedDamage;
