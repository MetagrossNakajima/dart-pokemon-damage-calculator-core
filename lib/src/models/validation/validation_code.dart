part of '../validation.dart';

/// 入力から妥当なドメインモデルを生成できない理由。
enum ValidationCode {
  required,
  outOfRange,
  unknownValue,
  duplicate,
  inconsistent,
}
