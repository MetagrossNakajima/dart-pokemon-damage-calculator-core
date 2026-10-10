import '../models/value_objects.dart';

final _critMoves = Set<MoveId>.unmodifiable({
  MoveId.wickedBlow,
  MoveId.flowerTrick,
  MoveId.frostBreath,
  MoveId.stormThrow,
  MoveId.surgingStrikes,
});

final _naturalMultiHitMoves = Set<MoveId>.unmodifiable({
  MoveId.doubleKick,
  MoveId.surgingStrikes,
  MoveId.doubleHit,
  MoveId.bonemerang,
  MoveId.doubleIronBash,
  MoveId.dragonDarts,
  MoveId.dualChop,
  MoveId.dualWingbeat,
  MoveId.gearGrind,
  MoveId.twineedle,
  MoveId.twinBeam,
  MoveId.tripleDive,
  MoveId.bulletSeed,
  MoveId.rockBlast,
  MoveId.icicleSpear,
  MoveId.pinMissile,
  MoveId.tailSlap,
  MoveId.armThrust,
  MoveId.barrage,
  MoveId.boneRush,
  MoveId.cometPunch,
  MoveId.doubleSlap,
  MoveId.furyAttack,
  MoveId.furySwipes,
  MoveId.spikeCannon,
  MoveId.waterShuriken,
  MoveId.scaleShot,
  MoveId.tripleAxel,
  MoveId.tripleKick,
  MoveId.populationBomb,
});

final _weightMoves = Set<MoveId>.unmodifiable({
  MoveId.lowKick,
  MoveId.grassKnot,
  MoveId.heavySlam,
  MoveId.heatCrash,
});

final _unsupportedMoves = Set<MoveId>.unmodifiable({
  MoveId.counter,
  MoveId.bide,
  MoveId.comeuppance,
  MoveId.mirrorCoat,
  MoveId.metalBurst,
  MoveId.psywave,
});

final _specialDamageMoves = Set<MoveId>.unmodifiable({
  MoveId.superFang,
  MoveId.naturesMadness,
  MoveId.ruination,
  MoveId.guardianofAlola,
  MoveId.finalGambit,
  MoveId.endeavor,
  MoveId.sonicBoom,
  MoveId.dragonRage,
  MoveId.seismicToss,
  MoveId.nightShade,
  MoveId.fissure,
  MoveId.sheerCold,
  MoveId.hornDrill,
  MoveId.guillotine,
});

bool isGuaranteedCritical(MoveId id) => _critMoves.contains(id);

bool isNaturalMultiHitMove(MoveId id) => _naturalMultiHitMoves.contains(id);

bool isWeightBasedMove(MoveId id) => _weightMoves.contains(id);

bool isUnsupportedMove(MoveId id) => _unsupportedMoves.contains(id);

bool isFixedDamageMove(MoveId id) => _specialDamageMoves.contains(id);
