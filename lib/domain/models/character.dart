import 'dart:math';
import 'skill.dart';

/// 버프 효과
class ActiveBuff {
  final String name;
  final double attackMultiplier;
  final double defenseMultiplier;
  double remainingSeconds;

  ActiveBuff({
    required this.name,
    this.attackMultiplier = 1.0,
    this.defenseMultiplier = 1.0,
    required this.remainingSeconds,
  });

  bool get isExpired => remainingSeconds <= 0;
  void tick(double dt) => remainingSeconds -= dt;
}

/// 지속 데미지 효과
class DotEffect {
  final String name;
  final double damagePerSecond;
  double remainingSeconds;

  DotEffect({
    required this.name,
    required this.damagePerSecond,
    required this.remainingSeconds,
  });

  bool get isExpired => remainingSeconds <= 0;
  void tick(double dt) => remainingSeconds -= dt;
}

/// 평타 공격 결과
class AttackResult {
  final double damage;
  final bool isCritical;

  AttackResult({required this.damage, required this.isCritical});
}

class Character {
  final String id;
  final String name;
  final bool isPlayer;

  double maxHp;
  double currentHp;
  double baseAttack;
  double baseDefense;
  double attackInterval; // 초 단위 공격 주기

  // 치명타
  double critChance;      // 치명타 확률 (기본 5%)
  double critMultiplier;  // 치명타 배율 (기본 1.5배)

  // 배율 (카드 임시 / 장비 영구 분리)
  double tempAttackMultiplier;    // 런 중 카드로 얻은 임시 배율
  double tempDefenseMultiplier;
  final double permAttackMultiplier;  // 장비/유물 영구 배율
  final double permDefenseMultiplier;

  List<Skill> skills;

  final List<ActiveBuff> activeBuffs = [];
  final List<DotEffect> dotEffects = [];

  double _attackTimer = 0;

  // 특수 플래그
  bool hasDeathsDoor = false;       // 죽음의 문턱 (1회 버티기)
  bool deathsDoorUsed = false;
  double lifestealRatio = 0.0;      // 흡혈 비율
  double damageReduction = 0.0;     // 받는 피해 감소 (0.0~1.0)
  bool ignoreEnemyDefense = false;  // 적 방어력 무시
  bool hasNoDefense = false;        // 내 방어력 0

  double shieldHp = 0;              // 보호막
  double stunTimer = 0;             // 기절 타이머 (0보다 크면 기절 상태)
  double counterChance = 0.0;       // 반격 확률
  double counterRatio = 0.5;        // 반격 데미지 비율
  double cooldownReductionRate = 0.0; // 스킬 쿨타임 감소 비율 (0.0 ~ 1.0)
  double rageAttackBonus = 0.0;     // HP 50% 이하일 때 공격력 보너스
  double executerBonus = 0.0;       // 적 HP 20% 이하일 때 공격력 보너스

  // 신규 특수 카드 효과 플래그
  bool hasFirstMove = false;        // 웨이브 시작 후 첫 5초간 공속 증가
  bool hasSteelEcho = false;        // 방어력이 공격력의 10%만큼 증가
  bool hasThornsArmor = false;      // 적 피격 시 적 방어력 영구 감소
  bool hasManaBackflow = false;     // 스킬 사용 시 쿨타임 초기화 확률
  bool hasWheelOfFate = false;      // 10초마다 랜덤 버프
  bool hasOverload = false;         // 공속 대폭 증가, 공격 시 HP 소모
  bool hasPrecisionShooting = false; // 치명타 미발생 시 확률 중첩
  double precisionShootingBonus = 0.0;

  // 신규 특수 카드 효과 수치 및 상태
  double lowHpDamageReduction = 0.0; // HP 30% 이하일 때 추가 피감
  double undyingHealRatio = 0.0;     // 처치 시 회복 비율
  double predatorTimer = 0.0;        // 포식자 버프 타이머
  double predatorSpeedBonus = 0.0;   // 포식자 버프 공속 보너스

  // 유물 효과 수치 (보유 시 자동 적용)
  double relicCritChanceBonus = 0.0;
  double relicCritMultBonus = 0.0;
  double relicAtkSpeedBonus = 0.0;
  double relicStunExtraDamageRatio = 0.0;
  int relicRerollBonus = 0;
  int relicExtraGold = 0;
  int relicStartCardBonus = 0;

  Character({
    required this.id,
    required this.name,
    required this.isPlayer,
    required this.maxHp,
    required this.baseAttack,
    required this.baseDefense,
    required this.attackInterval,
    List<Skill>? skills,
    this.critChance = 0.05,
    this.critMultiplier = 1.5,
    this.tempAttackMultiplier = 1.0,
    this.tempDefenseMultiplier = 1.0,
    this.permAttackMultiplier = 1.0,
    this.permDefenseMultiplier = 1.0,
  })  : currentHp = maxHp,
        skills = skills ?? [];

  bool get isAlive => currentHp > 0;
  double get hpRatio => (currentHp / maxHp).clamp(0.0, 1.0);

  double get effectiveAttack {
    double buffMult = activeBuffs.fold(1.0, (m, b) => m * b.attackMultiplier);
    double hpBonusMult = 1.0;
    // HP 50% 이하일 때 분노 효과 적용
    if (hpRatio <= 0.5 && rageAttackBonus > 0) {
      hpBonusMult += rageAttackBonus;
    }
    return baseAttack * tempAttackMultiplier * permAttackMultiplier * buffMult * hpBonusMult;
  }

  double get effectiveDefense {
    if (hasNoDefense) return 0;
    double buffMult = activeBuffs.fold(1.0, (m, b) => m * b.defenseMultiplier);
    double def = baseDefense * tempDefenseMultiplier * permDefenseMultiplier * buffMult;
    if (hasSteelEcho) {
      def += effectiveAttack * 0.1;
    }
    return def;
  }

  double get effectiveCritChance => critChance + relicCritChanceBonus;
  double get effectiveCritMultiplier => critMultiplier + relicCritMultBonus;

  /// 평타 공격 (치명타 판정 포함)
  AttackResult rollAttack() {
    double currentCritChance = effectiveCritChance;
    if (hasPrecisionShooting) {
      currentCritChance += precisionShootingBonus;
    }

    final isCrit = Random().nextDouble() < currentCritChance;

    if (hasPrecisionShooting) {
      if (isCrit) {
        precisionShootingBonus = 0;
      } else {
        precisionShootingBonus += 0.05;
      }
    }

    final rawDamage = effectiveAttack * (isCrit ? effectiveCritMultiplier : 1.0);
    return AttackResult(damage: rawDamage, isCritical: isCrit);
  }

  /// 데미지 받기 (방어력 적용)
  double takeDamage(double rawDamage, {bool ignoreDefense = false}) {
    final defense = ignoreDefense ? 0 : effectiveDefense;
    double reduced = (rawDamage - defense).clamp(1.0, double.infinity);
    
    double currentReduction = damageReduction;
    if (hpRatio <= 0.3 && lowHpDamageReduction > 0) {
      currentReduction += lowHpDamageReduction;
    }
    reduced *= (1.0 - currentReduction.clamp(0.0, 0.95));

    // 보호막 먼저 소모
    if (shieldHp > 0) {
      if (shieldHp >= reduced) {
        shieldHp -= reduced;
        return reduced;
      } else {
        reduced -= shieldHp;
        shieldHp = 0;
      }
    }

    // 죽음의 문턱: HP 1 이하로 안 죽음 (1회)
    if (hasDeathsDoor && !deathsDoorUsed && currentHp - reduced <= 0) {
      currentHp = 1;
      deathsDoorUsed = true;
      return reduced;
    }

    currentHp = (currentHp - reduced).clamp(0.0, maxHp);
    return reduced;
  }

  /// 회복
  double heal(double amount) {
    final before = currentHp;
    currentHp = (currentHp + amount).clamp(0.0, maxHp);
    return currentHp - before;
  }

  /// 공격 타이머 진행. 공격 타이밍이면 true
  bool tickAttack(double dt, {double speedMultiplier = 1.0}) {
    if (stunTimer > 0) return false; // 기절 중 공격 불가

    double finalSpeedMult = speedMultiplier + relicAtkSpeedBonus;
    if (predatorTimer > 0) finalSpeedMult += predatorSpeedBonus;

    _attackTimer += dt * finalSpeedMult;
    if (_attackTimer >= attackInterval) {
      _attackTimer -= attackInterval;
      return true;
    }
    return false;
  }

  /// 버프/DoT 틱. DoT 피해 합산 반환
  double tickEffects(double dt) {
    // 기절 타이머 감소
    if (stunTimer > 0) {
      stunTimer = (stunTimer - dt).clamp(0.0, double.infinity);
    }
    
    // 포식자 타이머 감소
    if (predatorTimer > 0) {
      predatorTimer = (predatorTimer - dt).clamp(0.0, double.infinity);
    }

    for (final b in activeBuffs) {
      b.tick(dt);
    }
    activeBuffs.removeWhere((b) => b.isExpired);

    double dotDamage = 0;
    for (final d in dotEffects) {
      dotDamage += d.damagePerSecond * dt;
      d.tick(dt);
    }
    dotEffects.removeWhere((d) => d.isExpired);

    if (dotDamage > 0) currentHp = (currentHp - dotDamage).clamp(0.0, maxHp);
    return dotDamage;
  }

  void addBuff(ActiveBuff buff) => activeBuffs.add(buff);
  void addDot(DotEffect dot) => dotEffects.add(dot);

  // ── 캐릭터 팩토리 (임시 수치 — 플레이 후 밸런스 조정 예정) ──

  factory Character.defaultPlayer() => Character(
        id: 'player',
        name: '용사',
        isPlayer: true,
        maxHp: 200,
        baseAttack: 20,
        baseDefense: 5,
        attackInterval: 1.2,
        skills: [Skill.fireball()],
      );

  /// 1-1 일반 몬스터
  factory Character.slime() => Character(
        id: 'slime',
        name: '슬라임',
        isPlayer: false,
        maxHp: 150,
        baseAttack: 10,
        baseDefense: 0,
        attackInterval: 1.8,
      );

  /// 1-2 일반 몬스터
  factory Character.slime2() => Character(
        id: 'slime2',
        name: '파란 슬라임',
        isPlayer: false,
        maxHp: 200,
        baseAttack: 14,
        baseDefense: 2,
        attackInterval: 1.7,
      );

  /// 1-1 보스
  factory Character.slimeBoss() => Character(
        id: 'slime_boss',
        name: '슬라임 보스',
        isPlayer: false,
        maxHp: 350,
        baseAttack: 18,
        baseDefense: 5,
        attackInterval: 1.5,
        skills: [Skill.poisonBlade()],
      );

  /// 1-3 최종 보스
  factory Character.kingSlime() => Character(
        id: 'slime_boss2',
        name: '킹 슬라임',
        isPlayer: false,
        maxHp: 600,
        baseAttack: 50,
        baseDefense: 10,
        attackInterval: 1.2,
        skills: [
          Skill.earthSlam(),
          Skill.slimeSplit(),
        ],
      );

  /// 2-1 몬스터
  factory Character.skeleton() => Character(
        id: 'skel1',
        name: '스켈레톤',
        isPlayer: false,
        maxHp: 600,
        baseAttack: 50,
        baseDefense: 10,
        attackInterval: 1.2,
        skills: [],
      );

  /// 2-3 보스: 스켈레톤 킹
  factory Character.skeletonBoss() => Character(
        id: 'skel_boss',
        name: '스켈레톤 킹',
        isPlayer: false,
        maxHp: 1200,
        baseAttack: 80,
        baseDefense: 25,
        attackInterval: 1.0,
        skills: [
          Skill.soulReap(),
          Skill.boneWall(),
        ],
      );
}
