import '../models/dto.dart';
import '../models/value_objects.dart';
import '../rules/move_rules.dart';
import 'calculation_context.dart';

bool isNaturalMultiHit(MoveId id) => isNaturalMultiHitMove(id);

bool appliesParentalBond(DamageEffectsContext context) =>
    context.attackerAbility == AbilityId.parentalBond &&
    !isNaturalMultiHit(context.move.id) &&
    !(context.battleField.format == BattleFormat.double && context.move.spread);
