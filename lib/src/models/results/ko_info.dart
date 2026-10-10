part of '../dto.dart';

/// 命中前提の確定数の探索状態。
enum KoStatus { resolved, limitReached, notApplicable }

/// 個々のヒット数ではなく、技の使用回数で数える確定数の表示区分。
enum KoCategory {
  alreadyKnockedOut,
  oneHit,
  twoHits,
  threeHits,
  fourHits,
  fiveOrMore,
  undetermined,
  notApplicable,
}

final class KoInfo {
  const KoInfo({
    required this.status,
    required this.evaluatedAttacks,
    this.possibleHits,
    this.guaranteedHits,
  });
  final KoStatus status;

  /// 評価した攻撃列の攻撃数。
  final int evaluatedAttacks;
  final int? possibleHits;
  final int? guaranteedHits;

  /// 確定1〜4発・5発以上と、未確定・対象外・攻撃前撃破の表示区分。
  ///
  /// [KoCategory.fiveOrMore] は4回以上の攻撃でも確定撃破できない場合を含み、
  /// 後続の攻撃で撃破できることまでは保証しない。
  /// 4回未満で未確定の攻撃列は [KoCategory.undetermined] とする。
  KoCategory get category {
    if (status == KoStatus.notApplicable) return KoCategory.notApplicable;
    final guaranteed = guaranteedHits;
    if (guaranteed == null) {
      return evaluatedAttacks >= 4
          ? KoCategory.fiveOrMore
          : KoCategory.undetermined;
    }
    return switch (guaranteed) {
      0 => KoCategory.alreadyKnockedOut,
      1 => KoCategory.oneHit,
      2 => KoCategory.twoHits,
      3 => KoCategory.threeHits,
      4 => KoCategory.fourHits,
      _ => KoCategory.fiveOrMore,
    };
  }
}

/// 外れを含む指定攻撃列の撃破率。整数の比を正確に保持する。
final class KnockoutProbability {
  const KnockoutProbability(this.weight, this.totalWeight);
  final BigInt weight;
  final BigInt totalWeight;
  bool get guaranteed => weight == totalWeight;
  double get probability {
    if (weight == BigInt.zero) return 0;
    // 分子・分母をdouble化せず、53ビットの仮数を整数の比から丸める。
    var exponent = weight.bitLength - totalWeight.bitLength;
    final alignment = math.max(0, -exponent);
    if ((weight << alignment) < (totalWeight << (exponent + alignment))) {
      exponent--;
    }
    // 非正規化数では2^-1074単位を保ち、表現可能な小さな確率を失わない。
    final shift = math.max(0, math.min(1074, 52 - exponent));
    final scaled = weight << shift;
    var significand = scaled ~/ totalWeight;
    final remainder = scaled.remainder(totalWeight) * BigInt.two;
    if (remainder > totalWeight ||
        (remainder == totalWeight && significand.isOdd)) {
      significand += BigInt.one;
    }
    return significand.toDouble() * math.pow(2.0, -shift);
  }
}
