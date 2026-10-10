part of '../dto.dart';

/// 計算結果を得られなかった理由。
///
/// 検証済み入力の計算APIは、未対応の仕様と計算量制限の失敗を返す。
enum FailureKind { unsupported, complexityExceeded }
