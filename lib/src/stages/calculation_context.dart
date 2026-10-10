import '../battle_effects.dart';

import '../models/dto.dart';
import '../models/models.dart';
import '../models/value_objects.dart';
import '../rules/ability_rules.dart';
import 'dart:math' as math;
import 'stage_00_pre_process.dart';

/// 技が1回当たるときのダメージ計算に使う、ポケモンや場の情報。
final class DamageEffectsContext {
  /// 指定されたポケモン・技・場の状態から、計算に必要な情報をまとめる。
  ///
  /// [attacker]は攻撃側、[defender]は防御側、[originalMove]は前処理前の技、
  /// [battleField]は場の状態。[hitIndex]は何発目かを表し、初撃を0とする。
  DamageEffectsContext(
    this.attacker,
    this.defender,
    this.originalMove,
    this.battleField,
    this.hitIndex,
  );

  /// 攻撃側のポケモンの状態。
  final PokemonState attacker;

  /// 防御側のポケモンの状態。
  final PokemonState defender;

  /// 特性などによるタイプや分類の変更を加える前の技。
  final Move originalMove;

  /// 天候・フィールド・対戦形式など、指定された場の状態。
  final BattleField battleField;

  /// 何発目の攻撃かを表す番号。初撃は0で、連続技の威力や2発目以降の補正に使う。
  final int hitIndex;

  /// この計算で有効な攻撃側の特性。無効な場合は`null`。
  late final attackerAbility = activeAbility(
    attacker,
    battleField,
    opponent: defender,
  );

  /// かたやぶりなどによる特性の無視を考慮する前の、防御側の有効な特性。
  ///
  /// 無効な場合は`null`。天候の判定にも使う。
  late final activeDefenderAbility = activeAbility(
    defender,
    battleField,
    opponent: attacker,
  );

  /// この計算で効果を発揮する攻撃側の道具。
  ///
  /// 消費済みなどで効果を発揮しない場合は`null`。
  late final attackerItem = activeItem(
    attacker,
    battleField,
    opponent: defender,
  );

  /// この計算で効果を発揮する防御側の道具。
  ///
  /// 消費済みなどで効果を発揮しない場合は`null`。
  late final defenderItem = activeItem(
    defender,
    battleField,
    opponent: attacker,
  );

  /// かたやぶりなどの効果も考慮した、この計算で有効な防御側の特性。
  ///
  /// 特性が無効になっている場合や、この攻撃で無視される場合は`null`。
  late final defenderAbility = _defenderAbility();

  /// 特性の効果も考慮した、この計算に影響する天候。
  ///
  /// 有効な天候がない場合は`null`。
  late final weather = _weather();

  /// 場に設定されているフィールド。効果を受けるかどうかは、地面にいるかなどで別途判断する。
  late final terrain = battleField.terrain;

  /// 特性・道具・場の状態を考慮して、攻撃側が地面にいるか。
  late final grounded = isGrounded(
    attacker,
    battleField,
    attackerAbility,
    attackerItem,
  );

  /// この攻撃で有効な特性・道具・場の状態を考慮して、防御側が地面にいるか。
  late final defenderGrounded = isGrounded(
    defender,
    battleField,
    defenderAbility,
    defenderItem,
  );

  /// 特性などによるタイプ・分類・威力の変更を加えた、この攻撃で使う技。
  late final move = _prepareMove();

  /// 場の設定や攻撃側のきんちょうかんにより、防御側がきのみを使えない状態か。
  bool get unnerveActive =>
      field(FieldEffect.unnerve) ||
      {
        AbilityId.unnerve,
        AbilityId.asOneGlastrier,
        AbilityId.asOneSpectrier,
      }.contains(attackerAbility);

  /// テラスタルを反映した防御側の現在のタイプ。
  List<PokemonType> get defenderTypes => currentTypes(defender);

  /// 特性などによる変更を加えた後の技が物理技か。
  bool get physical => move.category == Category.physical;

  /// ダメージ計算で防御側の「ぼうぎょ」を参照するか。
  ///
  /// 物理技に加え、サイコショック・サイコブレイク・しんぴのつるぎも該当する。
  bool get physicalDefense =>
      physical ||
      {MoveId.psyshock, MoveId.psystrike, MoveId.secretSword}.contains(move.id);

  /// えんかくやパンチグローブの効果も考慮して、この技で相手に接触するか。
  bool get contact =>
      move.flags.contains(MoveFlag.contact) &&
      attackerAbility != AbilityId.longReach &&
      !(attackerItem == ItemId.punchingGlove &&
          move.flags.contains(MoveFlag.punch));

  /// この攻撃で使う技が、[flag]で指定された性質を持つかを調べる。
  bool flag(MoveFlag flag) => move.flags.contains(flag);

  /// [effect]で指定された効果が場に設定されているかを調べる。
  bool field(FieldEffect effect) => battleField.effects.contains(effect);

  /// [pokemon]の現在HPを返す。未指定の場合は最大HPを使用する。
  int hp(PokemonState pokemon) =>
      pokemon.currentHp?.value ?? pokemon.stats.hp.value;

  /// [pokemon]のHPが満タンかを調べる。
  bool full(PokemonState pokemon) => hp(pokemon) == pokemon.stats.hp.value;
  AbilityId? _defenderAbility() {
    // 有効な特性のうち、かたやぶりなどで無視できるものを除く。
    // とくせいガードがあっても、すでに無効な特性を有効にはしない。
    if (defenderItem == ItemId.abilityShield) return activeDefenderAbility;
    final ignores =
        {
          AbilityId.moldBreaker,
          AbilityId.teravolt,
          AbilityId.turboblaze,
        }.contains(attackerAbility) ||
        {
          MoveId.sunsteelStrike,
          MoveId.moongeistBeam,
          MoveId.photonGeyser,
        }.contains(originalMove.id);
    if (ignores && canIgnoreAbility(activeDefenderAbility)) {
      return null;
    }
    return activeDefenderAbility;
  }

  Weather? _weather() {
    final abilities = [attackerAbility, activeDefenderAbility];
    if (attackerAbility == AbilityId.megaSol && !weatherSuppressed(abilities)) {
      return Weather.sunlight;
    }
    return effectiveWeather(battleField, abilities);
  }

  EffectiveMove _prepareMove() {
    return prepareEffectiveMove(this);
  }

  /// [pokemon]の体重に、[ability]と[item]の効果を加えた体重を返す。
  ///
  /// [ability]には有効な特性、[item]には効果を発揮する道具を指定する。
  /// 効果がない場合は、それぞれ`null`を指定する。
  /// 0.1kg単位で端数を切り捨てながら計算し、結果をkg単位で返す。
  double weight(PokemonState pokemon, AbilityId? ability, ItemId? item) {
    // 体重補正は0.1kg単位の整数で順に処理し、各半減時に切り捨てる。
    var hectograms = pokemon.weight.hectograms;
    if (ability == AbilityId.heavyMetal) hectograms *= 2;
    if (ability == AbilityId.lightMetal) {
      hectograms = math.max(1, hectograms ~/ 2);
    }
    if (item == ItemId.floatStone) hectograms = math.max(1, hectograms ~/ 2);
    return hectograms / 10;
  }
}
