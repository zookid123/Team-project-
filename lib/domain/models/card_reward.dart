import 'dart:math';
import 'package:app_project/domain/models/skill.dart';

enum CardGrade { common, rare, epic }

enum CardType {
  statUp,    // 스탯 강화
  newSkill,  // 새 스킬 획득
  heal,      // 즉시 회복
  critUp,    // 치명타 확률 증가
  critEffect, // 치명타 발동 시 특수 효과
  special,   // 특수 효과
  resetCooldown, // 스킬 쿨타임 초기화
  skillUpgrade,  // 기존 스킬 강화
}

class CardReward {
  final String id;
  final String name;
  final String description;
  final CardType type;
  final CardGrade grade;

  // statUp
  final double attackMultiplierBonus;
  final double attackBonus;
  final double defenseBonus;
  final double maxHpBonus;
  final double attackSpeedBonus; // 공격 주기 감소 비율 (0.2 = 20% 빨라짐)

  // critUp / critEffect
  final double critChanceBonus;
  final double critMultiplierBonus;
  final double critHealRatio; // 치명타 시 피해의 N% 회복

  // newSkill / skillUpgrade
  final Skill? skill;
  final String? targetSkillId;

  // heal
  final double healRatio; // 최대 HP의 N% 회복

  // special
  final double lifestealRatio;    // 흡혈 비율
  final double damageReduction;   // 받는 피해 감소
  final bool ignoreEnemyDefense;  // 적 방어력 무시
  final bool hasDeathsDoor;       // 죽음의 문턱
  final double rageAttackBonus;   // HP 50% 이하 공격력 보너스
  final double executerBonus;     // 적 HP 20% 이하 공격력 보너스
  final bool isShieldCard;        // 방어막 카드 여부
  final bool isStunStrike;        // 기절 일격 카드 여부
  final double counterChance;     // 반격 확률
  final double counterRatio;      // 반격 데미지 비율

  // 신규 카드 효과 플래그
  final bool hasFirstMove;
  final bool hasSteelEcho;
  final bool hasThornsArmor;
  final bool hasManaBackflow;
  final bool hasWheelOfFate;
  final bool hasOverload;
  final bool hasPrecisionShooting;

  CardReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.grade,
    this.attackMultiplierBonus = 0,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.maxHpBonus = 0,
    this.attackSpeedBonus = 0,
    this.critChanceBonus = 0,
    this.critMultiplierBonus = 0,
    this.critHealRatio = 0,
    this.skill,
    this.targetSkillId,
    this.healRatio = 0,
    this.lifestealRatio = 0,
    this.damageReduction = 0,
    this.ignoreEnemyDefense = false,
    this.hasDeathsDoor = false,
    this.rageAttackBonus = 0,
    this.executerBonus = 0,
    this.isShieldCard = false,
    this.isStunStrike = false,
    this.counterChance = 0,
    this.counterRatio = 0.5,
    this.hasFirstMove = false,
    this.hasSteelEcho = false,
    this.hasThornsArmor = false,
    this.hasManaBackflow = false,
    this.hasWheelOfFate = false,
    this.hasOverload = false,
    this.hasPrecisionShooting = false,
  });

  // ── 카드 풀 ──────────────────────────────────────

  static List<CardReward> get _commonPool => [
        CardReward(id: 'atk_pct', name: '힘의 각성', description: '공격력 +30%',
            type: CardType.statUp, grade: CardGrade.common, attackMultiplierBonus: 0.30),
        CardReward(id: 'def_up', name: '강철 피부', description: '방어력 +20%',
            type: CardType.statUp, grade: CardGrade.common, defenseBonus: 0.20),
        CardReward(id: 'hp_up', name: '생명의 샘', description: '최대 HP +30%',
            type: CardType.statUp, grade: CardGrade.common, maxHpBonus: 0.30),
        CardReward(id: 'potion', name: '포션', description: '현재 HP 30% 회복',
            type: CardType.heal, grade: CardGrade.common, healRatio: 0.30),
        CardReward(id: 'spd_up', name: '빠른 손', description: '공격 속도 +20%',
            type: CardType.statUp, grade: CardGrade.common, attackSpeedBonus: 0.20),
        CardReward(id: 'crit_up_sm', name: '예리한 감각', description: '치명타 확률 +10%',
            type: CardType.critUp, grade: CardGrade.common, critChanceBonus: 0.10),
        CardReward(id: 'dmg_red_sm', name: '굳은 살', description: '받는 피해 -10%',
            type: CardType.special, grade: CardGrade.common, damageReduction: 0.10),
        CardReward(id: 'combo', name: '날카로운 눈', description: '공격력 +15%, 치명타 확률 +5%',
            type: CardType.statUp, grade: CardGrade.common,
            attackMultiplierBonus: 0.15, critChanceBonus: 0.05),
        CardReward(id: 'tough', name: '근성', description: '최대 HP +35, 방어력 +5',
            type: CardType.statUp, grade: CardGrade.common,
            maxHpBonus: 35, defenseBonus: 5),
        CardReward(id: 'skill_heal', name: '회복의 빛 습득', description: '10초마다 최대 HP의 20%를 즉시 회복',
            type: CardType.newSkill, grade: CardGrade.common, skill: Skill.heal()),
        CardReward(id: 'first_move', name: '첫 수', description: '매 웨이브 시작 후 첫 5초간 공격 속도 50% 증가',
            type: CardType.special, grade: CardGrade.common, hasFirstMove: true),
        CardReward(id: 'steel_echo', name: '강철의 메아리', description: '방어력이 공격력의 10%만큼 추가 증가',
            type: CardType.special, grade: CardGrade.common, hasSteelEcho: true),
      ];

  static List<CardReward> get _rarePool => [
        CardReward(id: 'focus', name: '집중', description: '모든 스킬의 쿨타임을 50% 영구적으로 감소',
            type: CardType.resetCooldown, grade: CardGrade.rare),
        CardReward(id: 'lifesteal', name: '흡혈', description: '평타 피해의 20%만큼 HP를 회복',
            type: CardType.special, grade: CardGrade.rare, lifestealRatio: 0.20),
        CardReward(id: 'crit_up_md', name: '치명적 일격', description: '치명타 확률 +20%',
            type: CardType.critUp, grade: CardGrade.rare, critChanceBonus: 0.20),
        CardReward(id: 'crit_heal', name: '치명타 흡혈', description: '치명타 발생 시 피해량의 30%만큼 HP를 회복',
            type: CardType.critEffect, grade: CardGrade.rare, critHealRatio: 0.30),
        CardReward(id: 'rage', name: '분노', description: '현재 HP가 50% 이하일 때 공격력이 40% 증가',
            type: CardType.special, grade: CardGrade.rare, rageAttackBonus: 0.40),
        CardReward(id: 'executer', name: '처형자', description: '적의 HP가 30% 이하일 때 공격력이 50% 증가',
            type: CardType.special, grade: CardGrade.rare, executerBonus: 0.50),
        CardReward(id: 'dmg_red_md', name: '강인함', description: '받는 피해 -20%',
            type: CardType.special, grade: CardGrade.rare, damageReduction: 0.20),
        CardReward(id: 'berserker', name: '광전사', description: '공격 속도 +30%, 방어력 -15%',
            type: CardType.statUp, grade: CardGrade.rare,
            attackSpeedBonus: 0.30, defenseBonus: -0.15),
        CardReward(id: 'poison_coat', name: '독 코팅', description: '평타 적중 시 15% 확률로 3초간 초당 공격력의 50%만큼 지속 피해',
            type: CardType.newSkill, grade: CardGrade.rare, skill: Skill.poisonBlade()),
        CardReward(id: 'counter', name: '반격', description: '피격 시 10% 확률로 받은 피해의 90%를 반사',
            type: CardType.special, grade: CardGrade.rare, counterChance: 0.1, counterRatio: 0.9),
        CardReward(id: 'shield', name: '방어막', description: '전투 시작 시 최대 HP의 15% 보호막 부여',
            type: CardType.special, grade: CardGrade.rare, isShieldCard: true),
        CardReward(id: 'thorns_armor', name: '가시 갑옷', description: '적에게 맞을 때마다 보스의 방어력 1씩 영구 감소',
            type: CardType.special, grade: CardGrade.rare, hasThornsArmor: true),
        CardReward(id: 'mana_backflow', name: '마력 역류', description: '스킬 사용 시 20% 확률로 해당 스킬 쿨타임 즉시 초기화',
            type: CardType.special, grade: CardGrade.rare, hasManaBackflow: true),
        CardReward(id: 'precision_shooting', name: '정밀 사격', description: '치명타 미발생 시 치명타 확률 5%씩 중첩 (치명타 시 초기화)',
            type: CardType.special, grade: CardGrade.rare, hasPrecisionShooting: true),
      ];

  static List<CardReward> get _epicPool => [
        CardReward(id: 'deaths_door', name: '죽음의 문턱', description: '사망에 이르는 피해를 입어도 HP 1로 1회 버팀',
            type: CardType.special, grade: CardGrade.epic, hasDeathsDoor: true),
        CardReward(id: 'undying', name: '불사의 의지', description: '몬스터 처치 시 즉시 HP의 50%를 회복',
            type: CardType.special, grade: CardGrade.epic, healRatio: 0.50),
        CardReward(id: 'blood_pact', name: '피의 계약', description: '최대 HP -30%, 공격력 +60%',
            type: CardType.statUp, grade: CardGrade.epic,
            maxHpBonus: -0.30, attackMultiplierBonus: 0.60),
        CardReward(id: 'fatal_destiny', name: '치명적 운명', description: '치명타 확률 +30%, 치명타 시 HP 10% 회복',
            type: CardType.critEffect, grade: CardGrade.epic,
            critChanceBonus: 0.30, critHealRatio: 0.10),
        CardReward(id: 'predator', name: '포식자', description: '치명타 발생 시 5초간 공격 속도가 40% 증가',
            type: CardType.critEffect, grade: CardGrade.epic, attackSpeedBonus: 0.40),
        CardReward(id: 'perfect_strike', name: '완벽한 일격', description: '치명타 배율이 +100% 증가 (1.5→2.5배)',
            type: CardType.critUp, grade: CardGrade.epic, critMultiplierBonus: 1.0),
        CardReward(id: 'indomitable', name: '불굴', description: 'HP 30% 이하일 때 받는 피해 -50%, 공격력 +30%',
            type: CardType.special, grade: CardGrade.epic,
            damageReduction: 0.50, rageAttackBonus: 0.30),
        CardReward(id: 'vampire_lord', name: '흡혈 군주', description: '모든 공격에 25% 흡혈 효과 적용',
            type: CardType.special, grade: CardGrade.epic, lifestealRatio: 0.25),
        CardReward(id: 'doom_blade', name: '절망의 칼날', description: '적의 모든 방어력을 무시하지만, 자신의 방어력도 0',
            type: CardType.special, grade: CardGrade.epic, ignoreEnemyDefense: true),
        CardReward(id: 'fireball_upgrade', name: '파이어볼 강화', description: '파이어볼 데미지 +50%, 쿨타임 -30%, 크기 증가',
            type: CardType.skillUpgrade, grade: CardGrade.epic, targetSkillId: 'fireball'),
        CardReward(id: 'stun_strike', name: '기절 일격', description: '평타 공격 시 10% 확률로 1.5초간 기절',
            type: CardType.special, grade: CardGrade.epic, isStunStrike: true),
        CardReward(id: 'wheel_of_fate', name: '운명의 수레바퀴', description: '매 10초마다 [공격 2배/방어 2배/초당 10% 회복] 중 1개 5초간 발동',
            type: CardType.special, grade: CardGrade.epic, hasWheelOfFate: true),
        CardReward(id: 'overload', name: '과부하', description: '공격 속도 +100%, 단 공격 시 현재 HP 1% 소모',
            type: CardType.special, grade: CardGrade.epic, attackSpeedBonus: 0.50, hasOverload: true),
      ];

  /// 등급 확률: common 55% / rare 33% / epic 12%
  static CardGrade _rollGrade() {
    final r = Random().nextDouble();
    if (r < 0.55) return CardGrade.common;
    if (r < 0.88) return CardGrade.rare; // 0.55 + 0.33
    return CardGrade.epic;
  }

  static List<CardReward> _poolByGrade(CardGrade grade) {
    switch (grade) {
      case CardGrade.common: return _commonPool;
      case CardGrade.rare:   return _rarePool;
      case CardGrade.epic:   return _epicPool;
    }
  }

  /// 등급 확률 적용해서 랜덤 3장 뽑기 (중복 없음)
  static List<CardReward> drawThree({Set<String> excludeIds = const {}}) {
    final result = <CardReward>[];
    final currentDrawIds = <String>{};

    int attempts = 0;
    while (result.length < 3 && attempts < 100) {
      attempts++;
      final grade = _rollGrade();
      final pool = List<CardReward>.from(_poolByGrade(grade))
        ..removeWhere((c) => excludeIds.contains(c.id) || currentDrawIds.contains(c.id));
      
      if (pool.isEmpty) {
        // 해당 등급의 모든 카드가 이미 제외되었으면 다른 등급 시도
        continue;
      }

      pool.shuffle(Random());
      final card = pool.first;
      result.add(card);
      currentDrawIds.add(card.id);
    }

    // 만약 후보가 너무 부족해서 3장을 못 채웠다면, 제외 조건 없이 남은 풀에서 시도 (최후의 수단)
    if (result.length < 3) {
      final allPool = [..._commonPool, ..._rarePool, ..._epicPool]
        ..removeWhere((c) => currentDrawIds.contains(c.id));
      allPool.shuffle();
      while (result.length < 3 && allPool.isNotEmpty) {
        final card = allPool.removeAt(0);
        result.add(card);
        currentDrawIds.add(card.id);
      }
    }

    return result;
  }
}
