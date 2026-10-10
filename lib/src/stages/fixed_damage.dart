import 'dart:math' as math;

/// いかりのまえば・しぜんのいかり・カタストロフィ。
int halfRemainingHp(int hp) => math.max(1, hp ~/ 2);

/// ガーディアン・デ・アローラ。
int threeQuarterRemainingHp(int hp) => hp ~/ 4 * 3 + hp % 4 * 3 ~/ 4;

/// がむしゃら。
int endeavorDamage(int defenderHp, int attackerHp) =>
    math.max(0, defenderHp - attackerHp);
